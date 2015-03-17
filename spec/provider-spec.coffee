describe "HTML autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-html')
    waitsForPromise -> atom.packages.activatePackage('language-html')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-html').mainModule.getProvider()

    waitsFor -> Object.keys(provider.completions).length > 0
    waitsForPromise -> atom.workspace.open('test.html')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "returns no completions when not at the start of a tag", ->
    editor.setText('')
    expect(getCompletions().length).toBe 0

    editor.setText('d')
    editor.setCursorBufferPosition([0, 0])
    expect(getCompletions().length).toBe 0
    editor.setCursorBufferPosition([0, 1])
    expect(getCompletions().length).toBe 0

  it "returns no completions in style tags", ->
    editor.setText """
      <style>
      <
      </style>
    """
    editor.setCursorBufferPosition([1, 1])
    expect(getCompletions().length).toBe 0

  it "returns no completions in script tags", ->
    editor.setText """
      <script>
      <
      </script>
    """
    editor.setCursorBufferPosition([1, 1])
    expect(getCompletions().length).toBe 0

  it "autcompletes tag names without a prefix", ->
    editor.setText('<')
    editor.setCursorBufferPosition([0, 1])

    completions = getCompletions()
    expect(completions.length).toBe 112

    for completion in completions
      expect(completion.text.length).toBeGreaterThan 0

  it "autocompletes tag names with a prefix", ->
    editor.setText('<d')
    editor.setCursorBufferPosition([0, 2])

    completions = getCompletions()
    expect(completions.length).toBe 9

    expect(completions[0].text).toBe 'datalist'
    expect(completions[0].replacementPrefix).toBe 'd'
    expect(completions[1].text).toBe 'dd'
    expect(completions[2].text).toBe 'del'
    expect(completions[3].text).toBe 'details'
    expect(completions[4].text).toBe 'dfn'
    expect(completions[5].text).toBe 'dialog'
    expect(completions[6].text).toBe 'div'
    expect(completions[7].text).toBe 'dl'
    expect(completions[8].text).toBe 'dt'

    editor.setText('<D')
    editor.setCursorBufferPosition([0, 2])

    completions = getCompletions()
    expect(completions.length).toBe 9

    expect(completions[0].text).toBe 'datalist'
    expect(completions[0].replacementPrefix).toBe 'D'
    expect(completions[1].text).toBe 'dd'
    expect(completions[2].text).toBe 'del'
    expect(completions[3].text).toBe 'details'
    expect(completions[4].text).toBe 'dfn'
    expect(completions[5].text).toBe 'dialog'
    expect(completions[6].text).toBe 'div'
    expect(completions[7].text).toBe 'dl'
    expect(completions[8].text).toBe 'dt'

  it "autocompletes attribute names without a prefix", ->
    editor.setText('<div ')
    editor.setCursorBufferPosition([0, 5])

    completions = getCompletions()
    expect(completions.length).toBe 69

    for completion in completions
      expect(completion.text.length).toBeGreaterThan 0

    editor.setText('<marquee ')
    editor.setCursorBufferPosition([0, 9])

    completions = getCompletions()
    expect(completions.length).toBe 81

    for completion in completions
      expect(completion.text.length).toBeGreaterThan 0

  it "autocompletes attribute names with a prefix", ->
    editor.setText('<div c')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'class'
    expect(completions[0].replacementPrefix).toBe 'c'
    expect(completions[1].text).toBe 'contenteditable'
    expect(completions[2].text).toBe 'contextmenu'

    editor.setText('<div C')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'class'
    expect(completions[0].replacementPrefix).toBe 'C'
    expect(completions[1].text).toBe 'contenteditable'
    expect(completions[2].text).toBe 'contextmenu'

    editor.setText('<div c>')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'class'
    expect(completions[1].text).toBe 'contenteditable'
    expect(completions[2].text).toBe 'contextmenu'

    editor.setText('<div c></div>')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'class'
    expect(completions[1].text).toBe 'contenteditable'
    expect(completions[2].text).toBe 'contextmenu'

    editor.setText('<marquee di')
    editor.setCursorBufferPosition([0, 12])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'dir'
    expect(completions[1].text).toBe 'direction'

    editor.setText('<marquee dI')
    editor.setCursorBufferPosition([0, 12])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].text).toBe 'dir'
    expect(completions[1].text).toBe 'direction'

  it "autocompletes attribute values without a prefix", ->
    editor.setText('<div behavior=""')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'scroll'
    expect(completions[1].text).toBe 'slide'
    expect(completions[2].text).toBe 'alternate'

    editor.setText('<div behavior="')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'scroll'
    expect(completions[1].text).toBe 'slide'
    expect(completions[2].text).toBe 'alternate'

    editor.setText('<div behavior=\'')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'scroll'
    expect(completions[1].text).toBe 'slide'
    expect(completions[2].text).toBe 'alternate'

    editor.setText('<div behavior=\'\'')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].text).toBe 'scroll'
    expect(completions[1].text).toBe 'slide'
    expect(completions[2].text).toBe 'alternate'

  it "autocompletes attribute values with a prefix", ->
    editor.setText('<html behavior="" lang="e"')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].text).toBe 'eu'
    expect(completions[0].replacementPrefix).toBe 'e'
    expect(completions[1].text).toBe 'en'
    expect(completions[2].text).toBe 'eo'
    expect(completions[3].text).toBe 'et'
    expect(completions[4].text).toBe 'el'
    expect(completions[5].text).toBe 'es'

    editor.setText('<html behavior="" lang="E"')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].text).toBe 'eu'
    expect(completions[0].replacementPrefix).toBe 'E'
    expect(completions[1].text).toBe 'en'
    expect(completions[2].text).toBe 'eo'
    expect(completions[3].text).toBe 'et'
    expect(completions[4].text).toBe 'el'
    expect(completions[5].text).toBe 'es'

    editor.setText('<html behavior="" lang=\'e\'')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].text).toBe 'eu'
    expect(completions[1].text).toBe 'en'
    expect(completions[2].text).toBe 'eo'
    expect(completions[3].text).toBe 'et'
    expect(completions[4].text).toBe 'el'
    expect(completions[5].text).toBe 'es'
