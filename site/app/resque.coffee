CoffeeResque = require 'coffee-resque'

# Singleton Resque acessor
#
module.exports = class Resque

  # The Coffee Resque queue
  resque = null

  # Get the resque queue
  #
  # [Connection] the Resque Connection
  #
  @instance: ->
    return resque if resque

    if process.env.NODE_ENV is 'production'
      resque = CoffeeResque.connect {
        host: 'gar.redistogo.com'
        port: 9066
        password: process.env.REDIS_PWD
      }
    else
      resque = CoffeeResque.connect()

    resque
