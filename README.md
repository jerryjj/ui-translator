# UI-Translator

Translator server for RequireJS i18n files. See http://requirejs.org/docs/api.html#i18n for more details.
Currently the server requires that you have defined your root bundle in the top level module.

## Install

    npm install -g ui-translator

Example:

```javascript
//Contents of my/nls/colors.js
define({
    "root": {
        "red": "red",
        "blue": "blue",
        "green": "green"
    },
    "fr-fr": true
});
```

```javascript
//Contents of my/nls/fr-fr/colors.js
define({
    "red": "rouge",
    "blue": "bleu",
    "green": "vert"
});
```

then running the server with

    ui-translator my/

You may also pass second argument which is list of ignored paths for the parser. ie.

    ui-translator my/ my/other,my/third

Then when the parser walks through the root folder and if there would be my/other/nls -folder it would get ignored
