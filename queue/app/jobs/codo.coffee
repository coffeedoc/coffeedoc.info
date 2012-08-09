Codo = require 'codo'
rimraf   = require 'rimraf'
{exec}   = require 'child_process'
temp     = require 'temp'

Project = require './../models/project'
File    = require './../models/file'

# Resque job that for Codo documentation
#
module.exports = class CodoJob

  # Generate the codo documentation
  #
  # @param [String] id the Job id
  # @param [String] url the GitHub url
  # @param [String] commit the commit reference to checkout
  # @param [Function] done the callback
  #
  @generate: (id, url, commit, done) ->
    try
      # Validate the URL
      github = /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/
      throw new Error("The GitHub repository URL #{ url } is not valid!") unless github.test url

      [url, user, project] = url.match github
      url = url.replace(/^https?:/, 'git:')
      url = "#{ url }.git" unless /\.git/.test url

      ref = /[A-Za-z0-0_-][A-Za-z0-0_.-]*/
      throw new Error("The Git commit #{ commit } is not valid!") unless ref.test commit

      # Create temp dir for checkout
      temp.mkdir 'codo', (err, path) ->
        throw err if err

        # Clone git repository
        console.log "#{ id }: Clone repository #{ url } to #{ path }"

        process.chdir path
        exec "git clone #{ url } .", (err) ->
          throw err if err

          # Checkout revision
          console.log "#{ id }: Checkout revision #{ commit } for #{ url }"

          exec "git checkout #{ commit }", (err) ->
            throw err if err

            # Generate Codo documentation
            console.log "#{ id }: Generate Codo documentation for #{ url } (commit #{ commit })"

            # Write generated file to mongodb
            file = (filename, content) ->
              filePath = "#{ user }/#{ project }/#{ commit }/#{ filename }"
              console.log "#{ id }: Save file #{ filename } for project #{ user }/#{ project }"

              file = new File()
              file.path = filePath
              file.content = content
              file.live = false
              file.save (err) ->
                throw err if err

            # Documentation generated
            finish = (err) ->
              if err
                # Remove all the files that already have been generated
                File.remove { path: ///#{ user }/#{ project }/#{ commit }///, live: false }, -> throw err

              # Remove the files that are currently live
              File.remove { path: ///#{ user }/#{ project }/#{ commit }///, live: true }, (err, num) ->
                throw err if err

                console.log "#{ id }: Removed #{ num } live files for #{ url }"

                # ... and mark the newly generated file as live
                File.update { path: ///#{ user }/#{ project }/#{ commit }/// }, { live: true }, { multi: true }, (err, num) ->
                  throw err if err

                  console.log "#{ id }: Added #{ num } live files for #{ url }"

                  # Update existing project
                  Project.findOne { user: user, project: project }, (err, proj) ->
                    throw err if err

                    unless proj
                      console.log "#{ id }: Create new project #{ user }/#{ project }"

                      proj = new Project()
                      proj.user = user
                      proj.project = project

                    unless commit in proj.versions
                      proj.versions.push(commit)
                      master = proj.versions.filter (v) -> v is 'master'
                      other  = proj.versions.filter (v) -> v isnt 'master'
                      proj.versions = master.concat other.sort().reverse()

                    proj.updated = new Date()

                    proj.save (err, num) ->
                      throw err if err

                      console.log "#{ id }: Project #{ user }/#{ project } saved."

                      rimraf path, (err) ->
                        console.log "#{ id }: Finished #{ user }/#{ project }."
                        done()

            Codo.run finish, file, 'UA-33919772-1', { name: 'CoffeeDoc.info', href: '/', target: '_top' }

    catch error
      msg = error?.message || error
      console.log "#{ id }: Error processing #{ url }: #{ msg }"
      done error
