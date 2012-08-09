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
    url    = req.param 'url'
    commit = req.param('commit') || 'master'

    console.log "New website checkout received for #{ url }"

    # Validate the URL
    urlFormat    = /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/
    commitFormat = /[A-Za-z0-0_-][A-Za-z0-0_.-]*/

    # Valid request
    if urlFormat.test(url) and commitFormat.test(commit)

      [url, user, project] = url.match urlFormat
      url = url.replace(/^https?:/, 'git:')
      url = "#{ url }.git" unless /\.git/.test url

      id = Resque.enqueue 'codo', 'generate', [url, commit]
      console.log "Create new job for #{ url } (#{ commit })"

      res.send id

    # Wrong url or commit format
    else
      res.send 412

  # Returns the state of a checkout
  #
  @state: (req, res) ->
    Resque.status req.param('id'), (err, status) ->
      res.send if err then 500 else status

  # Redirect www.coffeedoc.info to coffeedoc.info
  #
  @redirect: (req, res, next) ->
    if /^www/.test req.headers.host
      res.redirect "http://#{ req.headers.host.replace(/^www\./, '') + req.url }"
    else
      next()

  # Show a 404 page
  #
  @notFound: (req, res) ->
    res.render 'not_found', { url: req.url }
