path = require 'path'
fs = require 'fs'
request = require 'request'

mdnHTMLURL = 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element'
mdnJSONAPI = 'https://developer.mozilla.org/en-US/search.json?topic=html&highlight=false'
TagsURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlTags.json'

fetch = ->
  tagsPromise = new Promise (resolve) ->
    request {json: true, url: TagsURL}, (error, response, tags) ->
      if error?
        console.error(error.message)
        resolve(null)

      if response.statusCode isnt 200
        console.error("Request for HtmlTags.json failed: #{response.statusCode}")
        resolve(null)

      resolve(tags)

  tagsPromise.then (tags) ->
    return unless tags?

    MAX = 10
    queue = Object.keys(tags)
    running = []
    docs = {}

    new Promise (resolve) ->
      checkEnd = ->
        resolve(docs) if queue.length is 0 and running.length is 0

      removeRunning = (tagName) ->
        index = running.indexOf(tagName)
        running.splice(index, 1) if index > -1

      runNext = ->
        checkEnd()
        if queue.length isnt 0
          tagName = queue.pop()
          running.push(tagName)
          run(tagName)

      run = (tagName) ->
        url = "#{mdnJSONAPI}&q=#{tagName}"
        request {json: true, url}, (error, response, searchResults) ->
          if not error? and response.statusCode is 200
            handleRequest(tagName, searchResults)
          else
            console.error "Req failed #{url}; #{response.statusCode}, #{error}"
          removeRunning(tagName)
          runNext()

      handleRequest = (tagName, searchResults) ->
        if searchResults.documents?
          for doc in searchResults.documents
            # MDN groups h1 through h6 under a single "Heading Elements" page
            if doc.url is "#{mdnHTMLURL}/#{tagName}" or (/^h\d$/.test(tagName) and doc.url is "#{mdnHTMLURL}/Heading_Elements")
              if doc.tags.includes('Obsolete')
                docs[tagName] = "The #{tagName} element is obsolete. Avoid using it and update existing code if possible."
              else if doc.tags.includes('Deprecated')
                docs[tagName] = "The #{tagName} element is deprecated. Avoid using it and update existing code if possible."
              else
                docs[tagName] = filterExcerpt(tagName, doc.excerpt)
              return
        console.log "Could not find documentation for #{tagName}"

      runNext() for [0..MAX]
      return

filterExcerpt = (tagName, excerpt) ->
  beginningPattern = /^the html [a-z-]+ element (\([^)]+\) )?(is )?(\w+)/i
  excerpt = excerpt.replace beginningPattern, (match) ->
    matches = beginningPattern.exec(match)
    firstWord = matches[3]
    firstWord[0].toUpperCase() + firstWord.slice(1)
  periodIndex = excerpt.indexOf('.')
  excerpt = excerpt.slice(0, periodIndex + 1) if periodIndex > -1
  excerpt

# Save a file if run from the command line
if require.main is module
  fetch().then (docs) ->
    if docs?
      fs.writeFileSync(path.join(__dirname, 'tag-docs.json'), "#{JSON.stringify(docs, null, '  ')}\n")
    else
      console.error 'No docs'

module.exports = fetch
