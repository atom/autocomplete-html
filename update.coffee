# Run this to update the static list of tag/attributes stored in this package's
# package.json file.

path = require 'path'
fs = require 'fs'
request = require 'request'

exitIfError = (error) ->
  if error?
    console.error(error.message)
    return process.exit(1)

getTags = (callback) ->
  requestOptions =
    url: 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlTags.json'
    json: true

  request requestOptions, (error, response, tags) ->
    return callback(error) if error?

    if response.statusCode isnt 200
      return callback(new Error("Request for HtmlTags.json failed: #{response.statusCode}"))

    for tag, options of tags
      delete options.attributes if options.attributes?.length is 0

    callback(null, tags)

getAttributes = (callback) ->
  requestOptions =
    url: 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlAttributes.json'
    json: true

  request requestOptions, (error, response, attributes) ->
    return callback(error) if error?

    if response.statusCode isnt 200
      return callback(new Error("Request for HtmlAttributes.json failed: #{response.statusCode}"))

    for attribute, options of attributes
      delete attributes[attribute] if attribute.indexOf('/') isnt -1
      delete options.attribOption if options.attribOption?.length is 0

    callback(null, attributes)

getTags (error, tags) ->
  exitIfError(error)

  getAttributes (error, attributes) ->
    exitIfError(error)

    completions = {tags, attributes}
    fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(completions, null, 0)}\n")
