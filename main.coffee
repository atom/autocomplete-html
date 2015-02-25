fs = require 'fs'
path = require 'path'

trailingWhitespace = /\s$/
attributePattern = /\s+([a-z][-a-z]*)\s*=\s*$/

module.exports =
  selector: '.text.html'
  id: 'autocomplete-html-htmlprovider'

  activate: -> @loadCompletions()

  getProvider: -> providers: [this]

  requestHandler: (request) ->
    if @isAttributeValueStartWithNoPrefix(request)
      @getAllAttributeValueCompletions(request)
    else if @isAttributeValueStartWithPrefix(request)
      @getAttributeValueCompletionsForPrefix(request)
    else if @isAttributeStartWithNoPrefix(request)
      @getAllAttributeNameCompletions()
    else if @isAttributeStartWithPrefix(request)
      @getAttributeNameCompletionsForPrefix(request.prefix)
    else if @isTagStartWithNoPrefix(request)
      @getAllTagNameCompletions()
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletionsForPrefix(request.prefix)
    else
      []

  isTagStartWithNoPrefix: ({prefix, scope}) ->
    scopes = scope.getScopesArray()
    prefix is '<' and scopes.length is 1 and scopes[0] is 'text.html.basic'

  isTagStartTagWithPrefix: ({prefix, scope}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)
    @hasTagScope(scope.getScopesArray())

  isAttributeStartWithNoPrefix: ({prefix, scope}) ->
    return false unless trailingWhitespace.test(prefix)
    @hasTagScope(scope.getScopesArray())

  isAttributeStartWithPrefix: ({prefix, scope}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)

    scopes = scope.getScopesArray()
    return true if scopes.indexOf('entity.other.attribute-name.html') isnt -1

    return false unless @hasTagScope(scopes)

    scopes.indexOf('punctuation.definition.tag.html') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.end.html') isnt -1

  isAttributeValueStartWithNoPrefix: ({scope, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false unless lastPrefixCharacter in ['"', "'"]
    scopes = scope.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  isAttributeValueStartWithPrefix: ({scope, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false if lastPrefixCharacter in ['"', "'"]
    scopes = scope.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  hasTagScope: (scopes) ->
    scopes.indexOf('meta.tag.any.html') isnt -1 or
      scopes.indexOf('meta.tag.other.html') isnt -1 or
      scopes.indexOf('meta.tag.block.any.html') isnt -1 or
      scopes.indexOf('meta.tag.inline.any.html') isnt -1 or
      scopes.indexOf('meta.tag.structure.any.html') isnt -1

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.html') isnt -1 or
      scopes.indexOf('string.quoted.single.html') isnt -1

  getAllTagNameCompletions: ->
    completions = []
    for tag, attributes of @completions.tags
      completions.push({word: tag, prefix: ''})
    completions

  getTagNameCompletionsForPrefix: (prefix) ->
    completions = []
    for tag, attributes of @completions.tags when tag.indexOf(prefix) is 0
      completions.push({word: tag, prefix})
    completions

  getAllAttributeNameCompletions: ->
    completions = []
    for attribute, options of @completions.attributes
      completions.push({word: attribute, prefix: ''}) if options.global
    completions

  getAttributeNameCompletionsForPrefix: (prefix) ->
    completions = []
    for attribute, options of @completions.attributes when attribute.indexOf(prefix) is 0
      completions.push({word: attribute, prefix}) if options.global
    completions

  getPreviousAttribute: (editor, cursor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    line = line.substring(0, cursor.getBufferColumn()).trim()

    # Remove everything until the opening quote
    quoteIndex = line.length - 1
    quoteIndex-- while line[quoteIndex] and not (line[quoteIndex] in ['"', "'"])
    line = line.substring(0, quoteIndex)

    attributePattern.exec(line)?[1]

  getAllAttributeValueCompletions: ({editor, cursor}) ->
    completions = []
    attribute = @completions.attributes[@getPreviousAttribute(editor, cursor)]
    for option in attribute?.attribOption ? []
      completions.push({word: option, prefix: ''})
    completions

  getAttributeValueCompletionsForPrefix: ({editor, cursor, prefix}) ->
    completions = []
    attribute = @completions.attributes[@getPreviousAttribute(editor, cursor)]
    for option in attribute?.attribOption ? [] when option.indexOf(prefix) is 0
      completions.push({word: option, prefix})
    completions

  loadCompletions: ->
    @completions = {}
    fs.readFile path.join(__dirname, 'completions.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return
