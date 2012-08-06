#!/usr/bin/env coffee

# Create tempdir
fs = require 'fs'
fs.mkdirSync(process.env.TMPDIR) unless fs.existsSync process.env.TMPDIR

kue      = require 'kue'
redis    = require 'redis'
temp     = require 'temp'
mongoose = require 'mongoose'
{exec}   = require 'child_process'
{Schema} = require 'mongoose'
Codo     = require 'codo'
rimraf   = require 'rimraf'

CodoProjectSchema = new Schema
  user:     { type: String }
  project:  { type: String }
  versions: { type: Array }
  updated:  { type: String }

CodoFileSchema = new Schema
  path:     { type: String, index: true }
  content:  { type: String }
  live:     { type: Boolean, default: false }

CodoProject = mongoose.model 'CodoProject', CodoProjectSchema
CodoFile    = mongoose.model 'CodoFile', CodoFileSchema

# Production configuration
if process.env.NODE_ENV is 'production'

  # Setup MongoHQ
  mongoose.connect "mongodb://nodejitsu:#{ process.env.MONGODB_PWD }@staff.mongohq.com:10090/nodejitsudb407113725252"

  # Setup RedisToGo
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com', { no_ready_check: true }
    client.auth process.env.REDIS_PWD
    client

else
  mongoose.connect 'mongodb://localhost/coffeedoc'

queue = kue.createQueue()

# Generate Codo documentation
queue.process 'checkout', (job, done) ->

  try
    # Validate URL
    github = /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([A-Za-z0-9]+)\/([A-Za-z0-9]+?)(?:\.git)?\/?$/
    throw new Error("The GitHub repository URL #{ job.data.url } is not valid!") unless github.test job.data.url

    [url, user, project] = job.data.url.match github
    url = url.replace(/^https?:/, 'git:')

    ref = /[A-Za-z0-0_-][A-Za-z0-0_.-]*/
    throw new Error("The Git commit #{ job.data.commit } is not valid!") unless ref.test job.data.commit
    commit = job.data.commit

    # Create temp dir for checkout
    temp.mkdir 'codo', (err, path) ->
      throw err if err

      # Clone git repository
      job.log "Clone repository #{ url } to #{ path }"
      process.chdir path

      exec "git clone #{ url } .", (err) ->
        throw err if err
        job.progress 1, 3

        # Checkout revision
        job.log "Checkout revision #{ commit }"
        exec "git checkout #{ commit }", (err) ->
          throw err if err
          job.progress 2, 3

          # Generate Codo documentation
          job.log 'Generate Codo documentation'

          # Write generated file to mongodb
          file = (filename, content) ->
            codoFile = new CodoFile()
            codoFile.path = "/#{ user }/#{ project }/#{ commit }/#{ filename }"
            codoFile.content = content
            codoFile.live = false
            codoFile.save()

          # Documentation generated
          finish = (err) ->
            if err
              # Remove all the files that already have been generated
              CodoFile.remove { path: ///\/#{ user }\/#{ project }\/#{ commit }///, live: false }
              throw err

            # Remove the files that are currently live
            CodoFile.remove { path: ///\/#{ user }\/#{ project }\/#{ commit }///, live: true }

            # ... and mark the newly generated file as live
            CodoFile.update { path: ///\/#{ user }\/#{ project }\/#{ commit }/// }, { live: true }

            # Update existing project
            CodoProject.findOne { user: user, project: project }, (err, proj) ->
              unless proj
                proj = new CodoProject()
                proj.user = user
                proj.project = project

              proj.versions.push(commit) unless commit in proj.versions
              proj.updated = new Date()
              proj.save()

              job.progress 3, 3
              done()

              rimraf path, ->

          Codo.run finish, file

  catch error
    job.log error.message
    done error

# Start Kue web interface
kue.app.set 'title', 'CoffeeDoc.info jobs queue'
kue.app.listen 3000, ->
  console.log 'Kue web is listening on port %d', 3000
