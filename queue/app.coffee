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

CodoProject = mongoose.model 'CodoProject', new Schema
  user:     { type: String }
  project:  { type: String }
  versions: { type: Array }
  updated:  { type: String }

CodoFile = mongoose.model 'CodoFile', new Schema
  path:     { type: String, index: true }
  content:  { type: String }
  live:     { type: Boolean, default: false }

queue = kue.createQueue()

# Generate Codo documentation
queue.process 'checkout', (job, done) ->

  try
    # Validate URL
    github = /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/
    throw new Error("The GitHub repository URL #{ job.data.url } is not valid!") unless github.test job.data.url

    [url, user, project] = job.data.url.match github
    url = url.replace(/^https?:/, 'git:')
    url = "#{ url }.git" unless /\.git/.test url

    ref = /[A-Za-z0-0_-][A-Za-z0-0_.-]*/
    throw new Error("The Git commit #{ job.data.commit } is not valid!") unless ref.test job.data.commit
    commit = job.data.commit

    jobLog = (log) ->
      job.log log
      console.log "#{ user }/#{ project }: #{ log }"

    # Create temp dir for checkout
    temp.mkdir 'codo', (err, path) ->
      throw err if err

      # Clone git repository
      jobLog "Clone repository #{ url } to #{ path }"

      process.chdir path

      exec "git clone #{ url } .", (err) ->
        throw err if err
        job.progress 1, 3

        # Checkout revision
        jobLog "Checkout revision #{ commit }"

        exec "git checkout #{ commit }", (err) ->
          throw err if err
          job.progress 2, 3

          # Generate Codo documentation
          jobLog 'Generate Codo documentation'

          # Write generated file to mongodb
          file = (filename, content) ->
            jobLog "Save file #{ filename }"

            codoFile = new CodoFile()
            codoFile.path = "#{ user }/#{ project }/#{ commit }/#{ filename }"
            codoFile.content = content
            codoFile.live = false
            codoFile.save()

          # Documentation generated
          finish = (err) ->
            if err
              # Remove all the files that already have been generated
              CodoFile.remove { path: ///#{ user }/#{ project }/#{ commit }///, live: false }, -> throw err

            # Remove the files that are currently live
            CodoFile.remove { path: ///#{ user }/#{ project }/#{ commit }///, live: true }, (err, num) ->
              throw err if err

              jobLog "Removed #{ num } live Codo files"

              # ... and mark the newly generated file as live
              CodoFile.update { path: ///#{ user }/#{ project }/#{ commit }/// }, { live: true }, { multi: true }, (err, num) ->
                throw err if err

                jobLog "Added #{ num } live Codo files"

                # Update existing project
                CodoProject.findOne { user: user, project: project }, (err, proj) ->
                  throw err if err

                  unless proj
                    jobLog "Create new project"

                    proj = new CodoProject()
                    proj.user = user
                    proj.project = project

                  proj.versions.push(commit) unless commit in proj.versions
                  proj.updated = new Date()

                  proj.save (err, num) ->
                    throw err if err

                    jobLog "Project saved"

                    job.progress 3, 3
                    done()

                    rimraf path, ->

          Codo.run finish, file, 'UA-33919772-1', { name: 'CoffeeDoc.info', href: '/', target: '_top' }

  catch error
    job.log error.message
    done error

# Start Kue web interface
kue.app.set 'title', 'CoffeeDoc.info jobs queue'
kue.app.listen 3000, ->
  console.log 'Kue web is listening on port %d', 3000
