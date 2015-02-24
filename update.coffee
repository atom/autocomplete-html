# Run this to update the static list of tag/attributes stored in this package's
# package.json file.

path = require 'path'
fs = require 'fs'
request = require 'request'

requestOptions =
  url: 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlTags.json'
  json: true

request requestOptions, (error, response, tags) ->
  if error?
    console.error(error.message)
    return process.exit(1)

  if response.statusCode isnt 200
    console.error("Request for HtmlTags.json failed: #{response.statusCode}")
    return process.exit(1)

  fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(tags, null, 0)}\n")
