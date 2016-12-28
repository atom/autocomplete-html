provider = require './provider'

module.exports =
  activate: -> provider.loadCompletions()

  deactivate: -> provider.deactivate()

  getProvider: -> provider
