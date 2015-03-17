provider = require './provider'

module.exports =
  activate: -> provider.loadCompletions()

  getProvider: -> provider
