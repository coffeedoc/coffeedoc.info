#!/usr/bin/env coffee

# Create tempdir
fs = require 'fs'
fs.mkdirSync(process.env.TMPDIR) unless fs.existsSync process.env.TMPDIR

kue   = require 'kue'
redis = require 'redis'
temp   = require 'temp'
{exec} = require 'child_process'

# Make temp directory

# Production configuration
if process.env.NODE_ENV is 'production'

  # Setup RedisToGo
  kue.redis.createClient = ->
    client = redis.createClient 9066, 'gar.redistogo.com', { no_ready_check: true }
    client.auth process.env.REDIS_PWD
    client

queue = kue.createQueue()

# Generate Codo documentation
queue.process 'checkout', (job, done) ->
  temp.mkdir 'codo', (err, path) ->
    if err
      done err

    # Clone git repository
    else
      job.log "Clone repository #{ job.data.url } to #{ path }"

      process.chdir path
      exec "git clone #{ job.data.url } .", (err) ->
        if err
          done err

        # Checkout revision
        else
          job.progress 1, 3
          job.log "Checkout revision #{ job.data.commit }"

          exec "git checkout #{ job.data.commit }", (err) ->
            if err
              done err

            # Generate Codo documentation
            else
              job.progress 2, 3

              try
                job.log 'Generate Codo documentation'
                codo  = require 'codo'
                codo.run()

                job.progress 3, 3

              catch err
                done err

              done()

# Start Kue web interface
kue.app.set 'title', 'CoffeeDoc.info jobs queue'
kue.app.listen 3000, ->
  console.log 'Kue web is listening on port %d', 3000
