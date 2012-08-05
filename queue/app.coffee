#!/usr/bin/env coffee

kue   = require 'kue'
redis = require 'redis'

if process.env.NODE_ENV is 'production'
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com', { no_ready_check: true }
    client.auth process.env.REDIS_PWD
    client

queue = kue.createQueue()
queue.process 'codo', (job, done) ->
  message = "Generate Codo docs for #{ job.data.url }"

  job.log message
  console.log message

  done()

kue.app.set 'title', 'CoffeeDoc.info jobs queue'
kue.app.listen 3000, ->
  console.log 'Kue web is listening on port %d', 3000
