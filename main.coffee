fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.text.html'
  id: 'autocomplete-html-htmlprovider'

  activate: -> @loadCompletions()

  getProvider: -> providers: [this]

  requestHandler: ({prefix, scope}) ->
    completions = []
    if prefix is '<'
      for tag, attributes of @completions
        completions.push({word: tag, prefix: ''})
    else if @isTagStartScope(scope)
      for tag, attributes of @completions when tag.indexOf(prefix) is 0
        completions.push({word: tag, prefix})
    completions

  isTagStartScope: (scope) ->
    scopes = scope.getScopesArray()
    scopes.indexOf('meta.tag.other.html')         isnt -1 or
    scopes.indexOf('meta.tag.block.any.html')     isnt -1 or
    scopes.indexOf('meta.tag.inline.any.html')    isnt -1 or
    scopes.indexOf('meta.tag.structure.any.html') isnt -1

  loadCompletions: ->
    @completions = {}
    fs.readFile path.join(__dirname, 'completions.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return
