#!/usr/bin/env coffee

express = require 'express'
routes  = require './routes'
http    = require 'http'
path    = require 'path'

app = express()
app.engine '.hamlc', require('haml-coffee').__express

app.configure ->
  app.set 'port', 8080
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'hamlc'

  app.use express.favicon()
  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, 'public'))

  app.locals.uglify = true

  #app.use require('stylus').middleware({
  #  src: __dirname + '/public'
  #  compress: true
  #})

app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure 'production', ->
  app.use express.errorHandler()

app.get('/', routes.index);

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port %d in %s mode', app.get('port'), app.settings.env
