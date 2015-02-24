fs = require 'fs'
path = require 'path'

trailingWhitespace = /\s$/

module.exports =
  selector: '.text.html'
  id: 'autocomplete-html-htmlprovider'

  activate: -> @loadCompletions()

  getProvider: -> providers: [this]

  requestHandler: (request) ->
    if @isTagStartWithNoPrefix(request)
      @getAllTagNameCompletions()
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletionsForPrefix(request.prefix)
    else
      []

  isTagStartWithNoPrefix: ({prefix, scope}) ->
    scopes = scope.getScopesArray()
    prefix is '<' and scopes.length is 1 and scopes[0] is 'text.html.basic'

  isTagStartTagWithPrefix: ({prefix, scope}) ->
    return false if trailingWhitespace.test(prefix)

    scopes = scope.getScopesArray()
    scopes.indexOf('meta.tag.other.html') isnt -1 or
    scopes.indexOf('meta.tag.block.any.html') isnt -1 or
    scopes.indexOf('meta.tag.inline.any.html') isnt -1 or
    scopes.indexOf('meta.tag.structure.any.html') isnt -1

  getAllTagNameCompletions: ->
    completions = []
    for tag, attributes of @completions
      completions.push({word: tag, prefix: ''})
    completions

  getTagNameCompletionsForPrefix: (prefix) ->
    completions = []
    for tag, attributes of @completions when tag.indexOf(prefix) is 0
      completions.push({word: tag, prefix})
    completions

  loadCompletions: ->
    @completions = {}
    fs.readFile path.join(__dirname, 'completions.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return
