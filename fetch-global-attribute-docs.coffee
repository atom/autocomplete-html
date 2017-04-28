path = require 'path'
fs = require 'fs'
request = require 'request'

mdnHTMLURL = 'https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes'
mdnJSONAPI = 'https://developer.mozilla.org/en-US/search.json?topic=html&highlight=false'
AttributesURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlAttributes.json'

fetch = ->
  attributesPromise = new Promise (resolve) ->
    request {json: true, url: AttributesURL}, (error, response, attributes) ->
      if error?
        console.error(error.message)
        resolve(null)

      if response.statusCode isnt 200
        console.error("Request for HtmlAttributes.json failed: #{response.statusCode}")
        resolve(null)

      resolve(attributes)

  attributesPromise.then (attributes) ->
    return unless attributes?

    MAX = 10
    queue = []
    for attribute, options of attributes
      # MDN is missing docs for aria attributes and on* event handlers
      if options.global and not attribute.startsWith('aria') and not attribute.startsWith('on') and attribute isnt 'role'
        queue.push(attribute)
    running = []
    docs = {}

    new Promise (resolve) ->
      checkEnd = ->
        resolve(docs) if queue.length is 0 and running.length is 0

      removeRunning = (attributeName) ->
        index = running.indexOf(attributeName)
        running.splice(index, 1) if index > -1

      runNext = ->
        checkEnd()
        if queue.length isnt 0
          attributeName = queue.pop()
          running.push(attributeName)
          run(attributeName)

      run = (attributeName) ->
        url = "#{mdnJSONAPI}&q=#{attributeName}"
        request {json: true, url}, (error, response, searchResults) ->
          if not error? and response.statusCode is 200
            handleRequest(attributeName, searchResults)
          else
            console.error "Req failed #{url}; #{response.statusCode}, #{error}"
          removeRunning(attributeName)
          runNext()

      handleRequest = (attributeName, searchResults) ->
        if searchResults.documents?
          for doc in searchResults.documents
            if doc.url is "#{mdnHTMLURL}/#{attributeName}"
              docs[attributeName] = filterExcerpt(attributeName, doc.excerpt)
              return
        console.log "Could not find documentation for #{attributeName}"

      runNext() for [0..MAX]
      return

filterExcerpt = (attributeName, excerpt) ->
  beginningPattern = /^the [a-z-]+ global attribute (is )?(\w+)/i
  excerpt = excerpt.replace beginningPattern, (match) ->
    matches = beginningPattern.exec(match)
    firstWord = matches[2]
    firstWord[0].toUpperCase() + firstWord.slice(1)
  periodIndex = excerpt.indexOf('.')
  excerpt = excerpt.slice(0, periodIndex + 1) if periodIndex > -1
  excerpt

# Save a file if run from the command line
if require.main is module
  fetch().then (docs) ->
    if docs?
      fs.writeFileSync(path.join(__dirname, 'global-attribute-docs.json'), "#{JSON.stringify(docs, null, '  ')}\n")
    else
      console.error 'No docs'

module.exports = fetch
