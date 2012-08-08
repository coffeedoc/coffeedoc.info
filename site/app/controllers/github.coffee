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

      # Generate Job ID
      id = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
        r = Math.random() * 16 | 0
        v = if c is 'x' then r else (r&0x3 | 0x8)
        v.toString 16

      console.log "Enque new GitHub checkout for repository #{ url } (#{ commit })"
      Resque.instance().enqueue 'codo', 'generate', [id, url, commit]

      res.send 200
