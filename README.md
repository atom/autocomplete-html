# HTML Autocomplete package
[![OS X Build Status](https://travis-ci.org/atom/autocomplete-html.svg?branch=master)](https://travis-ci.org/atom/autocomplete-html) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/bsaqbg1fljpd9q1b/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/autocomplete-html/branch/master) [![Dependency Status](https://david-dm.org/atom/autocomplete-html.svg)](https://david-dm.org/atom/autocomplete-html)

HTML tag and attribute autocompletions in Atom. Install
[autocomplete-plus](https://github.com/atom-community/autocomplete-plus) before installing this package.

This is powered by the list of HTML tags [here](https://github.com/adobe/brackets/blob/master/src/extensions/default/HTMLCodeHints/HtmlTags.json) and HTML attributes [here](https://github.com/adobe/brackets/blob/master/src/extensions/default/HTMLCodeHints/HtmlAttributes.json)

![html-completions](https://cloud.githubusercontent.com/assets/4392286/7382905/705e6174-ee59-11e4-88bf-40bd553a336c.gif)

You can update the prebuilt list of tags and attributes names and values by running the `update.coffee` file at the root of the repository and then checking-in the changed `completions.json` file.
