# Run this to update the static list of tag/attributes stored in this package's
# package.json file.

path = require 'path'
fs = require 'fs'
request = require 'request'
fetchTagDescriptions = require './fetch-tag-docs'
fetchGlobalAttributeDescriptions = require './fetch-global-attribute-docs'

TagsURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlTags.json'
AttributesURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlAttributes.json'

tagsPromise = new Promise (resolve) ->
  request {json: true, url: TagsURL}, (error, response, tags) ->
    if error?
      console.error(error.message)
      resolve(null)

    if response.statusCode isnt 200
      console.error("Request for HtmlTags.json failed: #{response.statusCode}")
      resolve(null)

    for tag, options of tags
      delete options.attributes if options.attributes?.length is 0

    resolve(tags)

tagDescriptionsPromise = fetchTagDescriptions()

attributesPromise = new Promise (resolve) ->
  request {json: true, url: AttributesURL}, (error, response, attributes) ->
    if error?
      console.error(error.message)
      resolve(null)

    if response.statusCode isnt 200
      console.error("Request for HtmlAttributes.json failed: #{response.statusCode}")
      resolve(null)

    for attribute, options of attributes
      delete options.attribOption if options.attribOption?.length is 0

    resolve(attributes)

globalAttributeDescriptionsPromise = fetchGlobalAttributeDescriptions()

Promise.all([tagsPromise, tagDescriptionsPromise, attributesPromise, globalAttributeDescriptionsPromise]).then (values) ->
  tags = values[0]
  tagDescriptions = values[1]
  attributes = values[2]
  attributeDescriptions = values[3]

  for tag of tags
    tags[tag].description = tagDescriptions[tag]

  for attribute, options of attributes
    attributes[attribute].description = attributeDescriptions[attribute] if options.global

  completions = {tags, attributes}
  fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(completions, null, '  ')}\n")
