describe "HTML autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      cursor: cursor
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
    expect(completions[1].word).toBe 'dd'
    expect(completions[2].word).toBe 'del'
    expect(completions[3].word).toBe 'details'
    expect(completions[4].word).toBe 'dfn'
    expect(completions[5].word).toBe 'dialog'
    expect(completions[6].word).toBe 'div'
    expect(completions[7].word).toBe 'dl'
    expect(completions[8].word).toBe 'dt'

  it "autocompletions attribute names without a prefix", ->
    editor.setText('<div ')
    editor.setCursorBufferPosition([0, 5])

    completions = getCompletions()
    expect(completions.length).toBe 69

    for completion in completions
      expect(completion.word.length).toBeGreaterThan 0

  it "autocompletions attribute names with a prefix", ->
    editor.setText('<div c')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'

    editor.setText('<div c>')
    editor.setCursorBufferPosition([0, 6])

    completions = getCompletions()
    expect(completions.length).toBe 3

    expect(completions[0].word).toBe 'class'
    expect(completions[1].word).toBe 'contenteditable'
    expect(completions[2].word).toBe 'contextmenu'
