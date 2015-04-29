# HTML Autocomplete Package [![Build Status](https://travis-ci.org/atom/autocomplete-html.svg?branch=master)](https://travis-ci.org/atom/autocomplete-html)

HTML tag and attribe autocompletions in Atom. Install
[autocomplete-plus](https://github.com/atom-community/autocomplete-plus) before
installing this package.

This is powered by the list of HTML tags [here](https://github.com/adobe/brackets/blob/master/src/extensions/default/HTMLCodeHints/HtmlTags.json)
and HTML attributes [here](https://github.com/adobe/brackets/blob/master/src/extensions/default/HTMLCodeHints/HtmlAttributes.json)

![html-completions](https://cloud.githubusercontent.com/assets/4392286/7382905/705e6174-ee59-11e4-88bf-40bd553a336c.gif)

You can update the prebuilt list of tags and attributes names and values by
running the `update.coffee` file at the root of the repository and then checking
in the changed `completions.json` file.
