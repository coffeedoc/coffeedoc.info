#!/usr/bin/env coffee

express = require 'express'
http    = require 'http'
path    = require 'path'
kue     = require 'kue'
redis   = require 'redis'

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
  app.use require('connect-assets')()
  app.use '/images', express.static(path.join(__dirname, 'assets', 'images'))

  app.locals.uglify = true

app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })
  app.queue = kue.createQueue()

app.configure 'production', ->
  app.use express.errorHandler()

  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com'
    client.auth "nodejitsu:#{ process.env.REDIS_PWD }"
    client

  app.queue = kue.createQueue()

app.get '/', (req, res) ->
  res.render 'index'

app.post '/checkout', (req, res) ->
  url    = req.param 'url'
  commit = req.param 'commit'
  scheme = req.param 'scheme'

  console.log "Enque new GitHub project for repository #{ url } (#{ commit })"

  app.queue.create('codo', {
    title: "Generate Codo documentation for repository at #{ url } (#{ commit })"
    url: url
    commit: commit
    scheme: scheme
  }).attempts(3).save()

  res.render 'index'

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port %d in %s mode', app.get('port'), app.settings.env
