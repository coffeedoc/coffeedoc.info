CoffeeResque = require 'coffee-resque'
CodoJobs     = require './jobs/codo'

# Singleton Resque acessor
#
module.exports = class Resque

# The Coffee Resque queue
  resque = null

  # Get the resque queue
  #
  # [Connection] the Resque Connection
  #
  @instance: ->
    return resque if resque

    if process.env.NODE_ENV is 'production'
      resque = CoffeeResque.connect {
        host: 'gar.redistogo.com'
        port: 9066
        password: process.env.REDIS_PWD
      }
    else
      resque = CoffeeResque.connect()

    resque

  # Start a worker on the jobs.
  #
  @work: ->
    resque = Resque.instance()
    worker = resque.worker('codo', CodoJobs)

    worker.on 'job', (worker, queue, job) ->
      job = JSON.stringify(job)
      job.start = new Date()

      resque.redis.sadd 'codo:working', job

    worker.on 'error', (err, worker, queue, job) ->
      job = JSON.stringify(job)
      job.end = new Date()
      job.error = err.message

      resque.redis.srem 'codo:working', job
      resque.redis.sadd 'codo:failed',  job

    worker.on 'success', (worker, queue, job) ->
      job = JSON.stringify(job)
      job.end = new Date()

      resque.redis.srem 'codo:working', job
      resque.redis.sadd 'codo:success', job

    worker.start()

  # Get the queued Jobs
  #
  # @param [Function] callback the result callback
  #
  @queued: (callback) ->
    Resque.instance().redis.lrange 'resque:queue:codo', 0, -1, (err, results) ->
      callback err, Resque.decode(results)

  # Get the working Jobs
  #
  # @param [Function] callback the result callback
  #
  @working: (callback) ->
    Resque.instance().redis.smembers 'codo:working', (err, results) ->
      callback err, Resque.decode(results)

  # Get the succeed Jobs
  #
  # @param [Function] callback the result callback
  #
  @succeed: (callback) ->
    Resque.instance().redis.smembers 'codo:success', (err, results) ->
      callback err, Resque.decode(results)

  # Get the failed Jobs
  #
  # @param [Function] callback the result callback
  #
  @failed: (callback) ->
    Resque.instance().redis.smembers 'codo:failed', (err, results) ->
      callback err, Resque.decode(results)

  # Decode a Redis result set with Jobs.
  #
  # @param [Array<String>] the redis result set
  # @return [Array<Object>] the decoded result
  #
  # @private
  #
  @decode: (results) ->
    return null unless results

    jobs = for result in results
      data = JSON.parse result
      {
      id:  data.args[0]
      url: data.args[1]
      commit:  data.args[2]
      }
