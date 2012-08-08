Mongoose = require 'mongoose'
{Schema} = require 'mongoose'

# Mongoose Project model.
#
class Project extends Schema

# Construct a project model
#
  constructor: ->
    super({
      user:     { type: String, index: true }
      project:  { type: String, index: true }
      versions: { type: Array }
      updated:  { type: String }
    })

module.exports = Mongoose.model 'Project', new Project()
