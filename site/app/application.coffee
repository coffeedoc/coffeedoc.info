http     = require 'http'
path     = require 'path'
fs       = require 'fs'

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

  # Start the application server
  #
  # @return [http.Server] the HTTP server
  #
  start: ->
    http.createServer(@app).listen @app.get('port'), =>
      console.log 'Site server listening on port %d in %s mode', @app.get('port'), @app.settings.env

  # Application configuration for all environments.
  #
  # @private
  #
  configuration: =>
    @app.set 'port', 8080

    @app.set 'views', path.join(__dirname, 'views')
    @app.set 'view engine', 'hamlc'
    @app.set 'view options', { layout: false }

    @app.locals = {
      codoVersion: Codo.version()
      coffeedocVersion: 'v' + JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf-8'))['version']
    }

    @app.use Express.bodyParser()
    @app.use Express.methodOverride()

    # Configure assets
    @app.use new Assets({ src: path.join(__dirname, 'assets') })
    @app.use '/images', Express.static path.join(__dirname, 'assets', 'images')
    @app.use Express.favicon path.join(__dirname, 'assets', 'images', 'favicon.ico')

    @routes()

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

    @app.get  '/checkout', GitHubController.checkoutInfo
    @app.post '/checkout', GitHubController.checkout

    @app.get '*', CoffeeDocController.notFound
