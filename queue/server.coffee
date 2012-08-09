#!/usr/bin/env coffee

# Create tempdir
fs = require 'fs'
fs.mkdirSync(process.env.TMPDIR) unless fs.existsSync process.env.TMPDIR

# Connect to MongoDB
Mongoose = require 'mongoose'

if process.env.NODE_ENV is 'production'
  Mongoose.connect "mongodb://nodejitsu:#{ process.env.MONGODB_PWD }@staff.mongohq.com:10090/nodejitsudb407113725252"
else
  Mongoose.connect 'mongodb://localhost/coffeedoc'

# Attach jobs
Resque = require './app/resque'
Resque.work()

# Start queue monitor app
Application = require('./app/application')
new Application().start()
