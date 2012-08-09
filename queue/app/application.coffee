Http     = require 'http'
Path     = require 'path'

Express    = require 'express'
Codo       = require 'codo'
HamlCoffee = require 'haml-coffee'
Assets     = require 'connect-assets'

QueueController = require './controllers/queue'

# CoffeeDoc.info Express.js application
#
module.exports = class Application

# Construct a new Express.js application
#
  constructor: ->
    @app = Express()
    @app.engine '.hamlc', HamlCoffee.__express

    @app.configure                @configuration
    @app.configure 'development', @development
    @app.configure 'production',  @production

    @routes()

  # Start the application server
  #
  # @return [http.Server] the HTTP server
  #
  start: ->
    server = Http.createServer(@app).listen @app.get('port'), =>
      console.log 'Queue server listening on port %d in %s mode', @app.get('port'), @app.settings.env

  # Application configuration for all environments.
  #
  # @private
  #
  configuration: =>
    @app.set 'port', 3000

    @app.set 'views', Path.join(__dirname, 'views')
    @app.set 'view engine', 'hamlc'
    @app.set 'view options', { layout: false }
    @app.locals = { codoVersion: Codo.version() }

    @app.use Express.bodyParser()
    @app.use Express.methodOverride()
    @app.use @app.router

    # Configure assets
    @app.use new Assets({ src: Path.join(__dirname, 'assets') })
    @app.use '/images', Express.static Path.join(__dirname, 'assets', 'images')
    @app.use Express.favicon Path.join(__dirname, 'assets', 'images', 'favicon.ico')

  # Development configuration
  #
  # @private
  #
  development: =>
    @app.use Express.logger 'dev'
    @app.use Express.errorHandler({ dumpExceptions: true, showStack: true })

  # Production configuration
  #
  # @private
  #
  production: =>
    @app.use Express.logger()
    @app.use Express.errorHandler()

  # Attach the application routes to the controllers.
  #
  routes: ->
    @app.get  '/',              QueueController.index
    @app.post '/clear/working', QueueController.clearWorking
    @app.post '/clear/succeed', QueueController.clearSucceed
    @app.post '/clear/failed',  QueueController.clearFailed
