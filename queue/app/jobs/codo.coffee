Async    = require 'async'
Codo     = require 'codo'
rimraf   = require 'rimraf'
{exec}   = require 'child_process'
temp     = require 'temp'

Project = require './../models/project'
File    = require './../models/file'

# Coffee Resque 'codo' job
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
    worker = new CodoJob.Generator(id, url, commit)

    Async.waterfall [
      worker.makeTempDirectory
      worker.cloneRepository
      worker.checkoutCommit
      worker.generateDocs
      worker.findProject
      worker.updateProject
      worker.removeTempDirectory
    ],
    (err, result) ->
      console.log("#{ id }: Error generating the docs: #{ err.message }") if err
      done err

  # The generate Codo job worker
  #
  class CodoJob.Generator

    # Construct a new generation Job
    #
    constructor: (@id, @url, @commit) ->
      [url, @user, @project] = url.match /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/

    # Create a temporary directory to checkout
    # and create the Codo documentation.
    #
    # @param [Function] done the callback
    #
    makeTempDirectory: (done) =>
      temp.mkdir 'codo', (err, path) =>
        @log "Temp directory #{ path } created."

        @previousWorkDir = process.cwd()
        process.chdir path

        done err, path

    # Clone the repository into the temporary directory
    #
    # @param [String] path the temp dir path
    # @param [Function] done the callback
    #
    cloneRepository: (@path, done) =>
      @log "Clone Git repository #{ @url }."
      exec "git clone #{ @url } .", done

    # Check out the git commit.
    #
    # @param [String] stdout the git clone output
    # @param [String] stderr the git clone error output
    # @param [Function] done the callback
    #
    checkoutCommit: (stdout, stderr, done) =>
      @log "Checkout revision #{ @commit }"
      exec "git checkout #{ @commit }", done

    # Generate the Codo documentation
    #
    # @param [String] stdout the git checkout output
    # @param [String] stderr the git checkout error output
    # @param [Function] done the callback
    #
    generateDocs: (stdout, stderr, done) =>
      @log 'Generate Codo documentation'
      Codo.run done, @writeFile, 'UA-33919772-1', { name: 'CoffeeDoc.info', href: '/', target: '_top' }

    # Find the project
    #
    # @param [Function] done the callback
    #
    findProject: (done) =>
      @log "Find existing project"
      Project.findOne { user: @user, project: @project }, done

    # Create or update the project
    #
    # @param [Project] project the project
    # @param [Function] done the callback
    #
    updateProject: (project, done) =>
      unless project
        @log "Create new project #{ @user }/#{ @project }"

        project = new Project()
        project.user = @user
        project.project = @project

      unless @commit in project.versions
        project.versions.push @commit
        master = project.versions.filter (v) -> v is 'master'
        other  = project.versions.filter (v) -> v isnt 'master'
        project.versions = master.concat other.sort().reverse()

      @log "Update project #{ @user }/#{ @project }"

      project.updated = new Date()
      project.save done

    # Remove the temporary checkout directory.
    #
    # @param [Project] project the updated project
    # @param [Number] num the number of records changed
    # @param [Function] done the callback
    #
    removeTempDirectory: (project, num, done) =>
      process.chdir @previousWorkDir
      rimraf @path, done

    # Write a generated file to the MongoDB
    #
    # @param [String] filename the file name
    # @param [String] content the file content
    #
    writeFile: (filename, content) =>
      path = "#{ @user }/#{ @project }/#{ @commit }/#{ filename }"
      @log "Save file #{ path }"
      File.findOneAndUpdate { path: path }, { path: path, content: content }, { upsert: true }, (err) ->
        @log "Error saving file #{ path }: #{ err }" if err

    # Log a worker status
    #
    # @param [String] msg the log message
    #
    log: (msg) =>
      console.log "#{ @id }: #{ msg }"
