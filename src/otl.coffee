path      = require 'path'
fs        = require 'fs'
fse       = require 'fs-extra' # https://npmjs.org/package/fs-extra
grunt     = require "grunt" # https://github.com/cowboy/grunt

stripFileExtension = (filename) ->
  fsplit = filename.split('.')
  fsplit.pop() # pop last part of filename, ext
  destName = fsplit.join('.')

parseOl = (rootdir, subdir, srcName, dstPath) ->
  basePath     = path.join(rootdir, subdir)
  fNameSrc     = path.join(basePath, srcName)
  fileNameOnly = stripFileExtension(srcName)
  fNameJade    = path.join(dstPath, subdir, fileNameOnly + '.jade')
  fNameHtml    = path.join(dstPath, subdir, fileNameOnly + '.html')

  # fs.readFile fNameSrc, 'utf8', (err, data) ->
  #   throw err  if err
  #   console.log data

  baseIndent = Array(5).join ' '

  outL = []
  array = fs.readFileSync(fNameSrc).toString().split("\n")
  spacesPerlevel = 2

  # for i of array
  #   console.log i, array[i]

  indent = (level = 1) ->
    s = ''
    if level > 0
      s = '                                                   '.substr(0, level * spacesPerlevel)
    s

  currLevel = -1
  for i of array
    line = array[i]
    heading = (line.replace /^\s+/g, "")
    continue if not heading.length

    level = ((line.length - heading.length) / spacesPerlevel) + 1

    if level != currLevel
      if level == 1 or currLevel == -1
        level = 1
        outL.push('ul.l1')
        outL.push(indent() + 'li.l1')
        outL.push(indent(2) + '| ' + heading)
        currLevel = 1

      else if level > currLevel
        level = currLevel = currLevel + 1
        outL.push(indent(currLevel + currLevel - 2) + 'ul.l' + level)
        outL.push(indent(currLevel + currLevel - 1) + 'li.l' + level)
        outL.push(indent(currLevel + currLevel) + '| ' + heading)

      else # level < currLevel
        currLevel = level
        outL.push(indent(currLevel + currLevel - 1) + 'li.l' + level)
        outL.push(indent(currLevel + currLevel) + '| ' + heading)

    else
      outL.push(indent(currLevel + currLevel - 1) + 'li.l' + level)
      outL.push(indent(currLevel + currLevel) + '| ' + heading)

  jadeStr = '''
!!! 5
html
  head
    meta(charset="utf-8")
    link(rel='stylesheet', media='screen', href='../ol.css')
  body(lang='en')

'''
  # prepend baseIndent for each line
  for line in outL
    jadeStr += baseIndent + line + "\n"

  
  # save this
  # fse.mkdir path.join(dstPath, subdir), (err) ->
  #   if err
  #     console.error err
  #   else
  #     # console.log "created directory:", path.join(dstPath, subdir)

  #     fs.writeFile fNameJade, jadeStr, (err) ->
  #       return console.log(err)  if err
  #       console.log "Saved to: " + fNameJade

  # until I can render jade from deep paths
  fs.writeFile path.join(dstPath, fileNameOnly + '.jade'), jadeStr, (err) ->
    console.log 'err', err if err
    # console.log "Saved to: " + path.join(dstPath, fileNameOnly + '.jade')


  # fn = jade.compile(jadeStr, {pretty:true})
  # html = fn({})

  # fs.writeFile fNameHtml, html, (err) ->
  #   return console.log(err) if err
  #   console.log "Saved to: " + fNameHtml


exports.parse = (srcPath, dstPath) ->
  grunt.file.recurse srcPath, (abspath, rootdir, subdir, filename) ->
    if grunt.file.isMatch('*.ol', filename)
      # parseOl path.join(rootdir, subdir), filename, dstPath
      parseOl rootdir, subdir, filename, dstPath