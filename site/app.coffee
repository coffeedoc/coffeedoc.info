#!/usr/bin/env coffee

express = require 'express'
http    = require 'http'
path    = require 'path'
kue     = require 'kue'
redis   = require 'redis'

app    = express()
socket = require 'socket.io'

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

  # Configure assets
  app.use require('connect-assets')()
  app.use '/images', express.static(path.join(__dirname, 'assets', 'images'))

# Development settings
app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })
  app.queue = kue.createQueue()

# Production settings
app.configure 'production', ->
  app.use express.errorHandler()

  # Configure RedisToGo
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com', { no_ready_check: true }
    client.auth process.env.REDIS_PWD
    client

  app.queue = kue.createQueue()

# Show coffeedoc.info homepage
app.get '/', (req, res) ->
  res.render 'index', { success: true, message: "Holla" }

# Github checkout hook
app.post '/checkout', (req, res) ->
  payload = JSON.parse req.param('payload')

  unless payload.repository.private
    url = payload.repository.url
    commit = 'master'

    console.log "Enque new GitHub checkout for repository #{ url } (#{ commit })"

    app.queue.create('codo', {
      title: "Generate Codo documentation for repository at #{ url } (#{ commit })"
      url: url
      commit: commit
    }).attempts(3).save()

  res.send 'OK'

# Start the express server
server = http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port %d in %s mode', app.get('port'), app.settings.env

io = socket.listen server
io.sockets.on 'connection', (socket) ->

  # Checkout a new project
  #
  socket.on 'checkout', (data) ->
    job = app.queue.create('checkout', {
      title: "Generate Codo documentation for repository at #{ data.url } (#{ data.commit })"
      url: data.url
      commit: data.commit
    }).attempts(3).save()

    job.on 'progress', (progress) ->
      socket.emit 'progress', { progress: progress }

    job.on 'failed', ->
      socket.emit 'failed'

    job.on 'complete', ->
      socket.emit 'complete'
