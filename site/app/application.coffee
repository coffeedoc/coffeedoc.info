Http     = require 'http'
Path     = require 'path'

Express    = require 'express'
Codo       = require 'codo'
HamlCoffee = require 'haml-coffee'
Assets     = require 'connect-assets'
Mongoose   = require 'mongoose'

CoffeeDocController = require './controllers/coffeedoc'
CodoController      = require './controllers/codo'
GitHubController    = require './controllers/github'

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
    Http.createServer(@app).listen @app.get('port'), =>
      console.log 'Site server listening on port %d in %s mode', @app.get('port'), @app.settings.env

  # Application configuration for all environments.
  #
  # @private
  #
  configuration: =>
    @app.set 'port', 8080

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

    Mongoose.connect 'mongodb://localhost/coffeedoc'

  # Production configuration
  #
  # @private
  #
  production: =>
    @app.use Express.logger()
    @app.use Express.errorHandler()

    Mongoose.connect "mongodb://nodejitsu:#{ process.env.MONGODB_PWD }@staff.mongohq.com:10090/nodejitsudb407113725252"

  # Attach the application routes to the controllers.
  #
  routes: =>
    @app.get  '/*',         CoffeeDocController.redirect
    @app.get  '/',          CoffeeDocController.index
    @app.post '/add',       CoffeeDocController.add
    @app.get  '/state/:id', CoffeeDocController.state

    @app.get  /github\/(.+)\/assets\/codo\.js$/,  CodoController.script
    @app.get  /github\/(.+)\/assets\/codo\.css$/, CodoController.style

    @app.get  '/github/:user/:project', CodoController.latest
    @app.get  /github\/(.+)$/,          CodoController.show

    @app.post '/checkout', GitHubController.checkout
