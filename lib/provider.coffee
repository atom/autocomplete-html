COMPLETIONS = require '../completions.json'

attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/

module.exports =
  selector: '.text.html'
  disableForSelector: '.text.html .comment'
  filterSuggestions: true
  completions: COMPLETIONS

  getSuggestions: (request) ->
    if @isAttributeValueStart(request)
      @getAttributeValueCompletions(request)
    else if @isAttributeStart(request)
      @getAttributeNameCompletions(request)
    else if @isTagStart(request)
      @getTagNameCompletions(request)
    else
      []

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'attribute'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate', activatedManually: false)

  isTagStart: ({prefix, scopeDescriptor, bufferPosition, editor}) ->
    return @hasTagScope(scopeDescriptor.getScopesArray()) if prefix.trim() and prefix.indexOf('<') is -1

    # autocomplete-plus's default prefix setting does not capture <. Manually check for it.
    prefix = editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 1], bufferPosition])

    scopes = scopeDescriptor.getScopesArray()

    # Don't autocomplete in embedded languages
    prefix is '<' and scopes[0] is 'text.html.basic' and scopes.length is 1

  isAttributeStart: ({prefix, scopeDescriptor, bufferPosition, editor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return @hasTagScope(scopes) if not @getPreviousAttribute(editor, bufferPosition) and prefix and not prefix.trim()

    previousBufferPosition = [bufferPosition.row, Math.max(0, bufferPosition.column - 1)]
    previousScopes = editor.scopeDescriptorForBufferPosition(previousBufferPosition)
    previousScopesArray = previousScopes.getScopesArray()

    return true if previousScopesArray.indexOf('entity.other.attribute-name.html') isnt -1
    return false unless @hasTagScope(scopes)

    # autocomplete here: <tag |>
    # not here: <tag >|
    scopes.indexOf('punctuation.definition.tag.end.html') isnt -1 and
      previousScopesArray.indexOf('punctuation.definition.tag.end.html') is -1

  isAttributeValueStart: ({scopeDescriptor, bufferPosition, editor}) ->
    scopes = scopeDescriptor.getScopesArray()

    previousBufferPosition = [bufferPosition.row, Math.max(0, bufferPosition.column - 1)]
    previousScopes = editor.scopeDescriptorForBufferPosition(previousBufferPosition)
    previousScopesArray = previousScopes.getScopesArray()

    # autocomplete here: attribute="|"
    # not here: attribute=|""
    # or here: attribute=""|
    # or here: attribute="""|
    @hasStringScope(scopes) and @hasStringScope(previousScopesArray) and
      previousScopesArray.indexOf('punctuation.definition.string.end.html') is -1 and
      @hasTagScope(scopes) and
      @getPreviousAttribute(editor, bufferPosition)?

  hasTagScope: (scopes) ->
    for scope in scopes
      return true if scope.startsWith('meta.tag.') and scope.endsWith('.html')
    return false

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.html') isnt -1 or
      scopes.indexOf('string.quoted.single.html') isnt -1

  getTagNameCompletions: ({prefix, editor, bufferPosition}) ->
    # autocomplete-plus's default prefix setting does not capture <. Manually check for it.
    ignorePrefix = editor.getTextInRange([[bufferPosition.row, bufferPosition.column - 1], bufferPosition]) is '<'

    completions = []
    for tag, options of @completions.tags when ignorePrefix or firstCharsEqual(tag, prefix)
      completions.push(@buildTagCompletion(tag, options))
    completions

  buildTagCompletion: (tag, {description}) ->
    text: tag
    type: 'tag'
    description: description ? "HTML <#{tag}> tag"
    descriptionMoreURL: if description then @getTagDocsURL(tag) else null

  getAttributeNameCompletions: ({prefix, editor, bufferPosition}) ->
    completions = []
    tag = @getPreviousTag(editor, bufferPosition)
    tagAttributes = @getTagAttributes(tag)

    for attribute in tagAttributes when not prefix.trim() or firstCharsEqual(attribute, prefix)
      completions.push(@buildLocalAttributeCompletion(attribute, tag, @completions.attributes[attribute]))

    for attribute, options of @completions.attributes when not prefix.trim() or firstCharsEqual(attribute, prefix)
      completions.push(@buildGlobalAttributeCompletion(attribute, options)) if options.global

    completions

  buildLocalAttributeCompletion: (attribute, tag, options) ->
    snippet: if options?.type is 'flag' then attribute else "#{attribute}=\"$1\"$0"
    displayText: attribute
    type: 'attribute'
    rightLabel: "<#{tag}>"
    description: "#{attribute} attribute local to <#{tag}> tags"
    descriptionMoreURL: @getLocalAttributeDocsURL(attribute, tag)

  buildGlobalAttributeCompletion: (attribute, {description, type}) ->
    snippet: if type is 'flag' then attribute else "#{attribute}=\"$1\"$0"
    displayText: attribute
    type: 'attribute'
    description: description ? "Global #{attribute} attribute"
    descriptionMoreURL: if description then @getGlobalAttributeDocsURL(attribute) else null

  getAttributeValueCompletions: ({prefix, editor, bufferPosition}) ->
    completions = []
    tag = @getPreviousTag(editor, bufferPosition)
    attribute = @getPreviousAttribute(editor, bufferPosition)
    values = @getAttributeValues(tag, attribute)
    for value in values when not prefix or firstCharsEqual(value, prefix)
      completions.push(@buildAttributeValueCompletion(tag, attribute, value))

    if completions.length is 0 and @completions.attributes[attribute]?.type is 'boolean'
      completions.push(@buildAttributeValueCompletion(tag, attribute, 'true'))
      completions.push(@buildAttributeValueCompletion(tag, attribute, 'false'))

    completions

  buildAttributeValueCompletion: (tag, attribute, value) ->
    if @completions.attributes[attribute].global
      text: value
      type: 'value'
      description: "#{value} value for global #{attribute} attribute"
      descriptionMoreURL: @getGlobalAttributeDocsURL(attribute)
    else
      text: value
      type: 'value'
      rightLabel: "<#{tag}>"
      description: "#{value} value for #{attribute} attribute local to <#{tag}>"
      descriptionMoreURL: @getLocalAttributeDocsURL(attribute, tag)

  getPreviousTag: (editor, bufferPosition) ->
    {row} = bufferPosition
    while row >= 0
      tag = tagPattern.exec(editor.lineTextForBufferRow(row))?[1]
      return tag if tag
      row--
    return

  getPreviousAttribute: (editor, bufferPosition) ->
    # Remove everything until the opening quote (if we're in a string)
    quoteIndex = bufferPosition.column - 1 # Don't start at the end of the line
    while quoteIndex
      scopes = editor.scopeDescriptorForBufferPosition([bufferPosition.row, quoteIndex])
      scopesArray = scopes.getScopesArray()
      break if not @hasStringScope(scopesArray) or scopesArray.indexOf('punctuation.definition.string.begin.html') isnt -1
      quoteIndex--

    attributePattern.exec(editor.getTextInRange([[bufferPosition.row, 0], [bufferPosition.row, quoteIndex]]))?[1]

  getAttributeValues: (tag, attribute) ->
    # Some local attributes are valid for multiple tags but have different attribute values
    # To differentiate them, they are identified in the completions file as tag/attribute
    @completions.attributes[attribute]?.attribOption ? @completions.attributes["#{tag}/#{attribute}"]?.attribOption ? []

  getTagAttributes: (tag) ->
    @completions.tags[tag]?.attributes ? []

  getTagDocsURL: (tag) ->
    "https://developer.mozilla.org/en-US/docs/Web/HTML/Element/#{tag}"

  getLocalAttributeDocsURL: (attribute, tag) ->
    "#{@getTagDocsURL(tag)}#attr-#{attribute}"

  getGlobalAttributeDocsURL: (attribute) ->
    "https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/#{attribute}"

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
