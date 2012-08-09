Async  = require 'async'
Resque = require '../resque'

# Simple queue viewer
#
module.exports = class QueueController

  # Show the queue status
  #
  @index: (req, res) ->
    Async.parallel {
      queued: Resque.queued
      working: Resque.working
      succeed: Resque.succeed
      failed: Resque.failed
    },
    (err, results) ->
      res.render 'index', {
        queued:   results.queued
        working: results.working
        succeed:  results.succeed
        failed:   results.failed
      }
