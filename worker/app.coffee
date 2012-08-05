#!/usr/bin/env coffee

kue = require 'kue'

if process.env.NODE_ENV is 'production'
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com'
    client.auth "nodejitsu:#{ process.env.REDIS_PWD }"
    client

queue = kue.createQueue()

queue.process 'codo', (job, done) ->
  message = "Generate Codo docs for #{ job.data.url }"

  job.log message
  console.log message

  done()
