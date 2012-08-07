#!/usr/bin/env coffee

express  = require 'express'
http     = require 'http'
path     = require 'path'
kue      = require 'kue'
redis    = require 'redis'
mongoose = require 'mongoose'
{Schema} = require 'mongoose'
Codo     = require 'codo'

CodoProject = mongoose.model 'CodoProject', new Schema
  user:     { type: String, index: true }
  project:  { type: String, index: true }
  versions: { type: Array }
  updated:  { type: String }

CodoFile = mongoose.model 'CodoFile', new Schema
  path:     { type: String, index: true }
  content:  { type: String }
  live:     { type: Boolean, default: false }

queue = null

# Express application
#
app = express()
app.engine '.hamlc', require('haml-coffee').__express

app.configure ->
  app.set 'port', 8080

  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'hamlc'
  app.set 'view options', { layout: false }

  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router

  app.locals = { codoVersion: Codo.version() }

  # Configure assets
  app.use require('connect-assets')()
  app.use '/images', express.static(path.join(__dirname, 'assets', 'images'))
  app.use express.favicon path.join(__dirname, 'assets', 'images', 'favicon.ico')

# Development settings
#
app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })
  mongoose.connect 'mongodb://localhost/coffeedoc'
  queue = kue.createQueue()

# Production settings
#
app.configure 'production', ->
  app.use express.errorHandler()

  # Setup MongoHQ
  mongoose.connect "mongodb://nodejitsu:#{ process.env.MONGODB_PWD }@staff.mongohq.com:10090/nodejitsudb407113725252"

  # Setup RedisToGo
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com', { no_ready_check: true, parser: 'javascript' }
    client.auth process.env.REDIS_PWD, -> console.log 'Authenicated with redistogo.com'
    client

  queue = kue.createQueue()

# Redirect www to non-www
#
app.get '/*', (req, res, next) ->
  if /^www/.test req.headers.host
    res.redirect "http://#{ req.headers.host.replace(/^www\./, '') + req.url }"
  else
    next()

# Show coffeedoc.info homepage
#
app.get '/', (req, res) ->
  CodoProject.find {}, ['user', 'project', 'versions'], { sort: { user: 1, project: 1 } }, (err, docs) ->
    res.render 'index', { projects: docs }

# Serve Codo javascripts
#
app.get /github\/(.+)\/assets\/codo\.js$/, (req, res) ->
  res.header 'Content-Type', 'application/javascript'
  res.send Codo.script()

# Serve Codo stylesheets
#
app.get /github\/(.+)\/assets\/codo\.css$/, (req, res) ->
  res.header 'Content-Type', 'text/css'
  res.send Codo.style()

# Redirect to first version
#
app.get '/github/:user/:project', (req, res) ->
  user = req.params.user
  project = req.params.project

  CodoProject.findOne { user: user, project: project }, ['versions'], (err, doc) ->
    res.send if err then 404 else res.redirect "/github/#{ user }/#{ project }/#{ doc.versions.shift() }/"

# Show Codo generated files
#
app.get /github\/(.+)$/, (req, res) ->
  path = req.params[0]

  # Provide index.html functionality
  unless /(\.html|\.js|\.css)$/.test path
    if /\/$/.test path
      path += 'index.html'
    else
      return res.redirect "/github/#{ path }/"

  # Detect content type
  switch path
    when /\/.js$/ then res.header 'Content-Type', 'application/javascript'
    when /\/.css$/ then res.header 'Content-Type', 'text/css'
    when /\/.html$/ then res.header 'Content-Type', 'text/html'

  # Locate Codo file resource
  CodoFile.findOne { path: path, live: true }, (err, doc) ->
    res.send if err then 404 else doc.content

# Github checkout hook
#
app.post '/checkout', (req, res) ->
  payload = JSON.parse req.param('payload')

  unless payload.repository.private
    url = payload.repository.url
    commit = 'master'

    console.log "Enque new GitHub checkout for repository #{ url } (#{ commit })"

    queue.create('checkout', {
      title: "Generate Codo documentation for repository at #{ url } (#{ commit })"
      url: url
      commit: commit
    }).attempts(3).save()

    res.send 200

# Add project from the web page
#
app.post '/add', (req, res) ->
  url =req.param('url')
  commit = req.param('commit') || 'master'

  console.log "New website checkout received for #{ url }"

  job = queue.create('checkout', {
    title: "Generate Codo documentation for repository at #{ url } (#{ commit })"
    url: url
    commit: commit
  }).attempts(3).save (err) ->
    res.send if err then 404 else "#{ job.id }"

# Get the job status
app.get '/state/:id', (req, res) ->
  try
    id = parseInt(req.param('id'), 10)
    console.log "Get status for job #{ id }"

    kue.Job.get id, (err, job) ->
      res.send if err then 404 else job._state

  # Redis max connection reached
  catch err
    res.send 'unknown'

# Start the express server
server = http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port %d in %s mode', app.get('port'), app.settings.env
