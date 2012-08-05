#!/usr/bin/env coffee

kue = require 'kue'
jobs = kue.createQueue()

jobs.process 'codo', (job, done) ->
  console.log 'Generate codo docs', job, done