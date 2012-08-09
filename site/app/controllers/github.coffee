Resque = require '../resque'

# GitHub [post receive hook](https://help.github.com/articles/post-receive-hooks/)
#
module.exports = class GitHubController

  # Github checkout hook
  #
  @checkout: (req, res) ->
    payload = JSON.parse req.param('payload')

    unless payload.repository.private
      url = payload.repository.url
      commit = 'master'

      console.log "Enque new GitHub checkout for repository #{ url } (#{ commit })"
      Resque.enqueue 'codo', 'generate', [url, commit]

      res.send 200
