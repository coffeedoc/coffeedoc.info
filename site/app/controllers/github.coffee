Resque = require '../resque'

# GitHub [post receive hook](https://help.github.com/articles/post-receive-hooks/)
#
module.exports = class GitHubController

  # Github checkout info
  #
  @checkoutInfo: (req, res) ->
    res.render 'checkout'

  # Github checkout hook
  #
  @checkout: (req, res) ->
    try
      payload = JSON.parse req.param('payload')

    console.log 'Received GitHub checkout', payload

    if payload
      url    = payload.repository.url

      unless payload.repository.private
        commit = 'master'
        console.log "Enque new GitHub checkout for repository #{ url } (#{ commit })"
        Resque.enqueue 'codo', 'generate', [url, commit]
        res.send 200

      else
        console.log "Ignore private repository #{ url }"
        res.send 412

    else
      res.send 412
