fs = require 'fs'
path = require 'path'
css = require 'css'

trailingWhitespace = /\s$/
attributePattern = /\s+([a-zA-Z][-a-zA-Z]*)\s*=\s*$/
tagPattern = /<([a-zA-Z][-a-zA-Z]*)(?:\s|$)/
stylePattern = /<style[^>]*>([\s\S]*?)<\/style>/gmi

module.exports =
  selector: '.text.html'
  disableForSelector: '.text.html .comment'
  filterSuggestions: true

  getSuggestions: (request) ->
    {prefix} = request
    if @isAttributeValueStartWithNoPrefix(request)
      @getAttributeValueCompletions(request)
    else if @isAttributeValueStartWithPrefix(request)
      @getAttributeValueCompletions(request, prefix)
    else if @isAttributeStartWithNoPrefix(request)
      @getAttributeNameCompletions(request)
    else if @isAttributeStartWithPrefix(request)
      @getAttributeNameCompletions(request, prefix)
    else if @isTagStartWithNoPrefix(request)
      @getTagNameCompletions()
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletions(prefix)
    else
      []

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'attribute'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate', activatedManually: false)

  isTagStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    if prefix is '<' and scopes.length is 1
      scopes[0] is 'text.html.basic'
    else if prefix is '<' and scopes.length is 2
      scopes[0] is 'text.html.basic' and scopes[1] is 'meta.scope.outside-tag.html'
    else
      false

  isTagStartTagWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)
    @hasTagScope(scopeDescriptor.getScopesArray())

  isAttributeStartWithNoPrefix: ({prefix, scopeDescriptor}) ->
    return false unless trailingWhitespace.test(prefix)
    @hasTagScope(scopeDescriptor.getScopesArray())

  isAttributeStartWithPrefix: ({prefix, scopeDescriptor}) ->
    return false unless prefix
    return false if trailingWhitespace.test(prefix)

    scopes = scopeDescriptor.getScopesArray()
    return true if scopes.indexOf('entity.other.attribute-name.html') isnt -1
    return false unless @hasTagScope(scopes)

    scopes.indexOf('punctuation.definition.tag.html') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.end.html') isnt -1

  isAttributeValueStartWithNoPrefix: ({scopeDescriptor, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false unless lastPrefixCharacter in ['"', "'"]
    scopes = scopeDescriptor.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  isAttributeValueStartWithPrefix: ({scopeDescriptor, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false if lastPrefixCharacter in ['"', "'"]
    scopes = scopeDescriptor.getScopesArray()
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

  getTagNameCompletions: (prefix) ->
    completions = []
    for tag, attributes of @completions.tags when not prefix or firstCharsEqual(tag, prefix)
      completions.push(@buildTagCompletion(tag))
    completions

  buildTagCompletion: (tag) ->
    text: tag
    type: 'tag'
    description: "HTML <#{tag}> tag"
    descriptionMoreURL: @getTagDocsURL(tag)

  getAttributeNameCompletions: ({editor, bufferPosition}, prefix) ->
    completions = []
    tag = @getPreviousTag(editor, bufferPosition)
    tagAttributes = @getTagAttributes(tag)

    for attribute in tagAttributes when not prefix or firstCharsEqual(attribute, prefix)
      completions.push(@buildAttributeCompletion(attribute, tag))

    for attribute, options of @completions.attributes when not prefix or firstCharsEqual(attribute, prefix)
      completions.push(@buildAttributeCompletion(attribute)) if options.global

    completions

  buildAttributeCompletion: (attribute, tag) ->
    if tag?
      snippet: "#{attribute}=\"$1\"$0"
      displayText: attribute
      type: 'attribute'
      rightLabel: "<#{tag}>"
      description: "#{attribute} attribute local to <#{tag}> tags"
      descriptionMoreURL: @getLocalAttributeDocsURL(attribute, tag)
    else
      snippet: "#{attribute}=\"$1\"$0"
      displayText: attribute
      type: 'attribute'
      description: "Global #{attribute} attribute"
      descriptionMoreURL: @getGlobalAttributeDocsURL(attribute)

  getAttributeValueCompletions: ({editor, bufferPosition}, prefix) ->
    tag = @getPreviousTag(editor, bufferPosition)
    attribute = @getPreviousAttribute(editor, bufferPosition)
    values = @getAttributeValues(attribute, editor)
    for value in values when not prefix or firstCharsEqual(value, prefix)
      @buildAttributeValueCompletion(tag, attribute, value)

  buildAttributeValueCompletion: (tag, attribute, value) ->
    if @completions.attributes[attribute]?.global
      text: value
      type: 'value'
      description: "#{value} value for global #{attribute} attribute"
      descriptionMoreURL: @getGlobalAttributeDocsURL(attribute)
    else
      text: value
      type: 'value'
      description: "#{value} value for #{attribute} attribute local to <#{tag}>"
      descriptionMoreURL: @getLocalAttributeDocsURL(attribute, tag)

  loadCompletions: ->
    @completions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      @completions = JSON.parse(content) unless error?
      return

  getPreviousTag: (editor, bufferPosition) ->
    {row} = bufferPosition
    while row >= 0
      tag = tagPattern.exec(editor.lineTextForBufferRow(row))?[1]
      return tag if tag
      row--
    return

  getPreviousAttribute: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).trim()

    # Remove everything until the opening quote
    quoteIndex = line.length - 1
    quoteIndex-- while line[quoteIndex] and not (line[quoteIndex] in ['"', "'"])
    line = line.substring(0, quoteIndex)

    attributePattern.exec(line)?[1]

  getLocalStylesheets: (editor) ->
    source = editor.getText()
    while match = stylePattern.exec(source)
      match[1]

  getStylesheetsAtPath: (dir) ->
    stylesheets = []
    for file in fs.readdirSync(dir)
      filename = path.join(dir, file)
      if fs.lstatSync(filename).isDirectory()
        stylesheets = stylesheets.concat(@getStylesheetsAtPath(filename))
      else if path.extname(filename).toLowerCase() in ['.css', '.scss', '.less']
        stylesheets.push fs.readFileSync filename, 'utf-8'
    return stylesheets

  buildCSSCompletions: (editor) ->
    completions =
      cls: []
      ids: []
    stylesheets = @getLocalStylesheets(editor)
    for p in atom.project.getPaths()
      stylesheets = stylesheets.concat @getStylesheetsAtPath p
    for stylesheet in stylesheets
      for rule in css.parse(stylesheet, {silent: false}).stylesheet.rules
        for selector in rule.selectors
          if selector.startsWith('.')
            completions.cls.push(selector.slice(1))
          else if selector.startsWith('#')
            completions.ids.push(selector.slice(1))
    return completions

  getAttributeValues: (attribute, editor) ->
    if attribute?.toLowerCase() is 'class'
      return @buildCSSCompletions(editor).cls
    else if attribute?.toLowerCase() is 'id'
      return @buildCSSCompletions(editor).ids
    attribute = @completions.attributes[attribute]
    attribute?.attribOption ? []

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
