Project = require './../models/project'
Resque  = require '../resque'

# CoffeeDoc routes that handles www stripping
# and the homepage rendering.
#
module.exports = class CoffeeDocController

  # Show coffeedoc.info homepage with a list
  # of all projects.
  #
  @index: (req, res) ->
    Project.find {}, ['user', 'project', 'versions'], { sort: { user: 1, project: 1 } }, (err, docs) ->
      res.render 'index', { projects: docs }

  # Add project from the web page
  #
  @add: (req, res) ->
    url =req.param 'url'
    commit = req.param('commit') || 'master'

    # Generate Job ID
    id = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else (r&0x3 | 0x8)
      v.toString 16

    console.log "New website checkout received for #{ url }"
    Resque.instance().enqueue 'codo', 'generate', [id, url, commit]

    res.send id

  # Returns the state of a checkout
  #
  @state: (req, res) ->
    url    = req.param 'url'
    commit = req.param 'commit'
    id     = req.param 'id'
    job    = JSON.stringify class: 'generate', args: [id, url, commit]

    Resque.instance().redis.lrange 'resque:queue:codo', 0, -1, (err, queued) ->
      isQueued = false

      jobs = for result in queued
        data = JSON.parse result
        isQueued = true if data.id is id

      if isQueued
        console.log "#{ id }: #{ url } (#{ commit }) is queued"
        res.send 'queued'

      else
        Resque.instance().redis.sismember 'codo:working', job, (err, progress) ->
          if progress is 1
            console.log "#{ id }: #{ url } (#{ commit }) is in progress"
            res.send 'progress'

          else
            Resque.instance().redis.sismember 'codo:failed', job, (err, failed) ->
              if failed is 1
                console.log "#{ id }: #{ url } (#{ commit }) is failed"
                res.send 'failed'

              else
                Resque.instance().redis.sismember 'codo:success', job, (err, completed) ->
                  if completed is 1
                    console.log "#{ id }: #{ url } (#{ commit }) is completed"
                    res.send 'completed'

                  else
                    console.log "#{ id }: #{ url } (#{ commit }) is unknown"
                    res.send 'unknown'

  # Redirect www.coffeedoc.info to coffeedoc.info
  #
  @redirect: (req, res, next) ->
    if /^www/.test req.headers.host
      res.redirect "http://#{ req.headers.host.replace(/^www\./, '') + req.url }"
    else
      next()
