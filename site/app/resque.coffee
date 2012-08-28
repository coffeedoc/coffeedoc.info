Async  = require 'async'
_      = require 'underscore'

CoffeeResque = require 'coffee-resque'
Redis        = require 'redis'

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
      redis = Redis.createClient 9066, 'gar.redistogo.com', { parser: 'javascript' }
      redis.auth process.env.REDIS_PWD
      resque = CoffeeResque.connect({ redis: redis })
    else
      resque = CoffeeResque.connect()

    resque

  # Adds a new job to the queue. Simple
  # wrapper arround coffee-resque enqueue
  # that adds a job id.
  #
  # @param [String] worker the job name
  # @param [String] job the job function name
  # @param [Array] args the job arguments
  # @return [String] the job id
  #
  @enqueue: (worker, job, args) ->
    id = Resque.createJobId()
    args.unshift id
    Resque.instance().enqueue worker, job, args

    id

  # Start a worker on the jobs.
  #
  @work: ->
    resque = Resque.instance()
    CodoJobs = require './jobs/codo'
    worker = resque.worker('codo', CodoJobs)

    worker.on 'job', (worker, queue, job) ->
      job.start = new Date().toGMTString()
      resque.redis.sadd 'codo:working', JSON.stringify(job)

    worker.on 'error', (err, worker, queue, job) ->
      resque.redis.srem 'codo:working', JSON.stringify(job)

      job.end = new Date().toGMTString()
      job.error = err.message
      resque.redis.sadd 'codo:failed',  JSON.stringify(job)

    worker.on 'success', (worker, queue, job) ->
      resque.redis.srem 'codo:working', JSON.stringify(job)

      job.end = new Date().toGMTString()
      resque.redis.sadd 'codo:success', JSON.stringify(job)

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
      jobs = Resque.decode(results)
      callback err, _.sortBy jobs, (job) -> -1 * new Date(job.start).getTime()

  # Get the succeed Jobs
  #
  # @param [Function] callback the result callback
  #
  @succeed: (callback) ->
    jobs = Resque.instance().redis.smembers 'codo:success', (err, results) ->
      jobs = Resque.decode(results)
      callback err, _.sortBy jobs, (job) -> -1 * new Date(job.end).getTime()

  # Get the failed Jobs
  #
  # @param [Function] callback the result callback
  #
  @failed: (callback) ->
    jobs = Resque.instance().redis.smembers 'codo:failed', (err, results) ->
      jobs = Resque.decode(results)
      callback err, _.sortBy jobs, (job) -> -1 * new Date(job.end).getTime()

  # Clear the working queue.
  #
  # @param [Function] callback the result callback
  #
  @clearWorking: (callback) ->
    Resque.instance().redis.del 'codo:working', (err) -> callback err

  # Clear the succeed queue.
  #
  # @param [Function] callback the result callback
  #
  @clearSucceed: (callback) ->
    Resque.instance().redis.del 'codo:success', (err) -> callback err

  # Clear the failed queue.
  #
  # @param [Function] callback the result callback
  #
  @clearFailed: (callback) ->
    Resque.instance().redis.del 'codo:failed', (err) -> callback err

  # Returns the job id status
  #
  # @param [String] id the job id
  # @param [Function] callback the result callback
  # @return [String] the job status status
  #
  @status: (id, callback) ->
    try
      contains = (jobs) -> _.include(_.map(jobs, (job) -> job.id), id)

      Async.parallel {
      queued: Resque.queued
      working: Resque.working
      succeed: Resque.succeed
      failed: Resque.failed
      },
      (err, results) ->
        if contains results.succeed
          callback null, 'succeed'
        else if contains results.failed
          callback null, 'failed'
        else if contains results.working
          callback null, 'working'
        else if contains results.queued
          callback null, 'queued'
        else
          callback null, 'unknown'

    catch error
      callback error

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
      id:     data.args[0]
      url:    data.args[1]
      commit: data.args[2]
      start:  data.start
      end:    data.end
      error:  data.error
      }

  # Creates a unique job id
  #
  # @return [String] the job id
  # @private
  #
  @createJobId: ->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else (r&0x3 | 0x8)
      v.toString 16
