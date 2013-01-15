express = require('express')
path = require('path')
nlsParser = require('./lib/nlsParser')
_ = require('underscore')  

exports.parser = nlsParser
  
exit = -> process.exit(0)

PORT = process.env.PORT || 2001

exports.run = (argv) ->
  if argv.length < 3
    console.log 'USAGE: ui-translator PATH_TO_UI [BASE_PATHS_TO_IGNORE]'
    console.log 'BASE_PATHS_TO_IGNORE can be comma separated list of paths which will not be included in parser'
    console.log ''
    return exit()
  
  server = express()
  server.use express.bodyParser()
  server.set 'view engine', 'html'
  server.set 'views', "#{__dirname}/views"
  server.engine 'html', require('ejs').renderFile
  server.use express.static("#{__dirname}/static")
  
  ignore = []
  if argv.length > 3
    ignore = argv[3].split(',')
    ignore = _.map ignore, (ignf) -> path.normalize(ignf)
    
  UI_ROOT = path.normalize(argv[2])
  
  nlsParser.parse UI_ROOT, ignore, (err, data) ->
    selectedNls = null
    selectedLang = null
    if data.length
      selectedNls = data[0]
      selectedNls.idx = 0
      if selectedNls.langs.length
        selectedLang =
          name: selectedNls.langs[0]
          rootDb: selectedNls.i18n.root
          db: selectedNls.i18n[selectedNls.langs[0]]
      
    locals =
      message: null
      nlsObjs: data
      selectedNls: selectedNls
      selectedLang: selectedLang
    
    selectNls = (idx) ->
      selectedNls = data[idx]
      selectedNls.idx = idx
      selectedNls
    selectLang = (nls, lang) ->
      selectedLang =
        name: lang
        rootDb: nls.i18n.root
        db: nls.i18n[lang]
      selectedLang
        
    server.get "/:nlsIdx?/:lang?", (req, res) ->
      locals.selectedLang = null
      locals.message = null
      if req.params.nlsIdx
        locals.selectedNls = selectNls req.params.nlsIdx        
      if req.params.lang
        locals.selectedLang = selectLang locals.selectedNls, req.params.lang
      
      res.render 'editor', locals
    
    server.post "/:nlsIdx/new", (req, res) ->
      lang = req.body.lang
      data[req.params.nlsIdx].langs.push lang
      data[req.params.nlsIdx].i18n[lang] = {}
      
      res.redirect "/#{req.params.nlsIdx}/#{lang}"
    
    server.post "/:nlsIdx/:lang", (req, res) ->
      locals.selectedNls = selectNls req.params.nlsIdx
      locals.selectedLang = selectLang locals.selectedNls, req.params.lang
      
      if req.body.trans
        Object.keys(req.body.trans).forEach (key) ->
          tv = req.body.trans[key]
          data[req.params.nlsIdx].i18n[req.params.lang][key] = tv
      
      if req.body.removeKey
        req.body.removeKey.forEach (key) ->
          delete data[req.params.nlsIdx].i18n.root[key]
          data[req.params.nlsIdx].langs.forEach (l) ->
            delete data[req.params.nlsIdx].i18n[l][key]
      
      if req.body.newKey and req.body.newKey.length
        req.body.newKey.forEach (key, i) ->
          rv = req.body.newRoot[i]
          tv = req.body.newTrans[i]
          unless data[req.params.nlsIdx].i18n.root[key]
            data[req.params.nlsIdx].i18n.root[key] = rv
            data[req.params.nlsIdx].langs.forEach (l) ->
              data[req.params.nlsIdx].i18n[l][key] = rv
          data[req.params.nlsIdx].i18n[req.params.lang][key] = tv
      
      nlsParser.store UI_ROOT, data, (err, data) ->      
        locals.message = 'Translations saved!'        
        locals.message = "#{err}" if err
        data = data
        res.render 'editor', locals
    
    server.listen PORT  
    console.log ''
    console.log 'Server listening'
    console.log "Point your browser to: http://localhost:#{PORT}"
