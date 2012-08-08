Resque = require '../resque'

# Simple queue viewer
#
module.exports = class QueueController

  # Decode a redis job set.
  #
  # @param [Array<String>] the redis result set
  # @return [Array<Object>] the decoded result
  #
  @decode: (results) ->
    return [] unless results

    jobs = for result in results
      data = JSON.parse result
      {
        id:  data.args[0]
        url: data.args[1]
        commit:  data.args[2]
      }

  # Show the queue status
  #
  @index: (req, res) ->
    Resque.instance().redis.lrange 'resque:queue:codo', 0, -1, (err, queued) ->
      Resque.instance().redis.smembers 'codo:working', (err, progress) ->
        Resque.instance().redis.smembers 'codo:failed', (err, failed) ->
          Resque.instance().redis.smembers 'codo:success', (err, succeed) ->

            res.render 'index', {
              queued:   QueueController.decode(queued)
              progress: QueueController.decode(progress)
              succeed:  QueueController.decode(succeed)
              failed:   QueueController.decode(failed)
            }
