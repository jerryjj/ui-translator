walk = require('walk')
path = require('path')
fs = require('fs')
async = require('async')
coffee = require('coffee-script')
_ = require('underscore')  

walk_options =
  followLinks: false
  
exports.collect = collect = (root, cb) ->
  walker = walk.walk(root, walk_options)
  nls_files = []

  walker.on "file", (root, fileStats, next) ->
    if root.match /nls/
      if fileStats.name.match /\.js$/
        nls_files.push path.normalize "#{root}/#{fileStats.name}"
      if fileStats.name.match /\.coffee$/
        nls_files.push path.normalize "#{root}/#{fileStats.name}"
      
    next()

  walker.on "end", ->
    cb(null, nls_files)

parseFile = (root, file_path, root_i18n, next) ->
  #console.log 'parseFile',file_path
  
  group_name = null
  type = null
  
  define = (opts) ->
    i18n = opts
    langs = []
    rootPath = null
    unless root_i18n      
      Object.keys(opts).forEach (key) ->
        return if key is 'root'
        langs.push key      
      i18n = opts.root
      rootPath = file_path.replace "#{root}/", ''
      rootPath = rootPath.replace "/#{group_name}.#{type}", ''
    
    parsed = {
      path: file_path
      groupName: group_name
      langs: langs
      i18n: i18n
      type: type
      rootPath: rootPath
    }
    next parsed
  
  content = fs.readFileSync file_path
  if file_path.match /\.coffee/
    group_name = file_path.split('/').pop().replace('.coffee', '')
    type = 'coffee'
    compiled = coffee.compile content.toString(), {header:false}
    eval(compiled)
  else
    group_name = file_path.split('/').pop().replace('.js', '')        
    type = 'js'
    eval(content.toString())

rootPathToLangPath = (root, lang) ->
  parts = root.split '/'
  fname = parts.pop()
  parts.push lang
  parts.push fname
  parts.join '/'
  
exports.parse = (root, ignore, cb) ->
  console.log 'Parsing nls files from',root
  console.log 'Ignoring following base directories',ignore if ignore
  parsed = []
  collect root, (err, files) ->
    root_files = []
    
    files.forEach (file_path) ->
      #console.log 'processing file_path',file_path
      parts = file_path.split '/'
      nlsIndex = parts.indexOf 'nls'
      if nlsIndex is parts.length-2
        root_files.push path.normalize file_path
    
    root_files = _.reject root_files, (file) ->
      status = false
      ignore.forEach (ignf) ->
        status = true if path.dirname(file).match "#{ignf}"
      return status
    
    console.log 'Found',root_files.length,'root localization files'
    
    tasks = []
    
    root_files.forEach (root_file) ->
      #console.log 'processing root_file',root_file
      tasks.push (cb) ->
        parseFile root, root_file, null, (rdata) ->
          paths = {root: root_file}
          i18n = {root: rdata.i18n}
          
          stasks = []          
          rdata.langs.forEach (lang) ->
            lang_file = rootPathToLangPath root_file, lang
            files.forEach (f) ->
              if f is lang_file
                stasks.push (scb) ->
                  parseFile root, f, rdata.i18n, (fd) ->
                    paths[lang] = fd.path
                    i18n[lang] = fd.i18n
                    scb()          
          async.series stasks, (e, r) ->
            parsed.push {
              type: rdata.type
              paths: paths
              rootPath: rdata.rootPath
              groupName: rdata.groupName
              langs: rdata.langs
              i18n: i18n
            }
            cb()
    
    async.series tasks, (err, res) ->
      cb(err, parsed)

saveFile = (root, file_path, lang, nls, next) ->
  unless file_path
    #console.log 'generating new file_path for lang',lang
    file_path = "#{root}/#{nls.rootPath}/#{lang}/#{nls.groupName}.#{nls.type}"    
  
  #console.log 'saveFile',file_path
  
  base_dir = path.dirname file_path  
  fs.mkdirSync base_dir unless fs.existsSync base_dir
  
  if nls.type is 'coffee'
    content = "define\n"
    if lang is 'root'
      content += "  \"root\":\n"
      Object.keys(nls.i18n.root).forEach (key) ->
        val = JSON.stringify nls.i18n.root[key]
        content += "    \"#{key}\": #{val}\n"
      nls.langs.forEach (l) ->
        content += "  \"#{l}\": true\n"
    else
      Object.keys(nls.i18n[lang]).forEach (key) ->
        val = JSON.stringify nls.i18n[lang][key]
        content += "  \"#{key}\": #{val}\n"
  else    
    content = "define("
    if lang is 'root'
      root_js = JSON.stringify nls.i18n.root
      content += "{\"root\": #{root_js},"
      nls.langs.forEach (l) ->
        content += "\"#{l}\": true,"
      content = content.substr(0,content.length-1)
      content += "}"
    else
      content += JSON.stringify nls.i18n[lang]
    content += ");"
    
  fs.writeFileSync(file_path, content, 'utf8') if content
  
  next()

exports.store = (root, data, cb) ->
  #console.log 'store nls',data
  
  tasks = []
  
  data.forEach (nls) ->
    tasks.push (cb) ->
      #console.log 'saving root',nls.paths.root
      saveFile root, nls.paths.root, 'root', nls, ->
        stasks = []
        nls.langs.forEach (lang) ->
          stasks.push (scb) ->
            #console.log "saving #{lang}",nls.paths[lang]
            saveFile root, nls.paths[lang], lang, nls, ->
              scb()
        async.series stasks, (e,r) ->
          cb()
  
  async.series tasks, (e,r) ->
    cb(null, data)
