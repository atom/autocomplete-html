describe "HTML autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      position: end
      scope: cursor.getScopeDescriptor()
      prefix: prefix
    provider.requestHandler(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-html')
    waitsForPromise -> atom.packages.activatePackage('language-html')

    runs ->
      [provider] = atom.packages.getActivePackage('autocomplete-html').mainModule.getProvider().providers

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
      expect(completion.word.length).toBeGreaterThan 0

  it "autocompletes tag names with a prefix", ->
    editor.setText('<d')
    editor.setCursorBufferPosition([0, 2])

    completions = getCompletions()
    expect(completions.length).toBe 9

    expect(completions[0].word).toBe 'datalist'
    expect(completions[0].prefix).toBe 'd'
    expect(completions[1].word).toBe 'dd'
    expect(completions[2].word).toBe 'del'
    expect(completions[3].word).toBe 'details'
    expect(completions[4].word).toBe 'dfn'
    expect(completions[5].word).toBe 'dialog'
    expect(completions[6].word).toBe 'div'
    expect(completions[7].word).toBe 'dl'
    expect(completions[8].word).toBe 'dt'

    editor.setText('<D')
    editor.setCursorBufferPosition([0, 2])

    completions = getCompletions()
    expect(completions.length).toBe 9

    expect(completions[0].word).toBe 'datalist'
    expect(completions[0].prefix).toBe 'D'
    expect(completions[1].word).toBe 'dd'
    expect(completions[2].word).toBe 'del'
    expect(completions[3].word).toBe 'details'
    expect(completions[4].word).toBe 'dfn'
    expect(completions[5].word).toBe 'dialog'
    expect(completions[6].word).toBe 'div'
    expect(completions[7].word).toBe 'dl'
    expect(completions[8].word).toBe 'dt'

  it "autocompletes attribute names without a prefix", ->
    editor.setText('<div ')
    editor.setCursorBufferPosition([0, 5])

    completions = getCompletions()
    expect(completions.length).toBe 69

    for completion in completions
      expect(completion.word.length).toBeGreaterThan 0

    editor.setText('<marquee ')
    editor.setCursorBufferPosition([0, 9])

    completions = getCompletions()
    expect(completions.length).toBe 81

    for completion in completions
      expect(completion.word.length).toBeGreaterThan 0

  it "autocompletes attribute names with a prefix", ->
    editor.setText('<div c')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[0].prefix).toBe 'c'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'

    editor.setText('<div C')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[0].prefix).toBe 'C'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'

    editor.setText('<div c>')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'

    editor.setText('<div c></div>')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'

    editor.setText('<marquee di')
    editor.setCursorBufferPosition([0, 12])

    completions = getCompletions()
    expect(completions.length).toBe 2

    expect(completions[0].word).toBe 'dir'
    expect(completions[1].word).toBe 'direction'

  it "autocompletes attribute values without a prefix", ->
    editor.setText('<div behavior=""')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'scroll'
    expect(completions[1].word).toBe 'slide'
    expect(completions[2].word).toBe 'alternate'

    editor.setText('<div behavior="')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'scroll'
    expect(completions[1].word).toBe 'slide'
    expect(completions[2].word).toBe 'alternate'

    editor.setText('<div behavior=\'')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'scroll'
    expect(completions[1].word).toBe 'slide'
    expect(completions[2].word).toBe 'alternate'

    editor.setText('<div behavior=\'\'')
    editor.setCursorBufferPosition([0, 15])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'scroll'
    expect(completions[1].word).toBe 'slide'
    expect(completions[2].word).toBe 'alternate'

  it "autocompletes attribute values with a prefix", ->
    editor.setText('<html behavior="" lang="e"')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].word).toBe 'eu'
    expect(completions[0].prefix).toBe 'e'
    expect(completions[1].word).toBe 'en'
    expect(completions[2].word).toBe 'eo'
    expect(completions[3].word).toBe 'et'
    expect(completions[4].word).toBe 'el'
    expect(completions[5].word).toBe 'es'

    editor.setText('<html behavior="" lang="E"')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].word).toBe 'eu'
    expect(completions[0].prefix).toBe 'E'
    expect(completions[1].word).toBe 'en'
    expect(completions[2].word).toBe 'eo'
    expect(completions[3].word).toBe 'et'
    expect(completions[4].word).toBe 'el'
    expect(completions[5].word).toBe 'es'

    editor.setText('<html behavior="" lang=\'e\'')
    editor.setCursorBufferPosition([0, 25])

    completions = getCompletions()
    expect(completions.length).toBe 6

    expect(completions[0].word).toBe 'eu'
    expect(completions[1].word).toBe 'en'
    expect(completions[2].word).toBe 'eo'
    expect(completions[3].word).toBe 'et'
    expect(completions[4].word).toBe 'el'
    expect(completions[5].word).toBe 'es'
