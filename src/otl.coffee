path      = require 'path'
fs        = require 'fs'
fse       = require 'fs-extra' # https://npmjs.org/package/fs-extra
grunt     = require "grunt" # https://github.com/cowboy/grunt

stripFileExtension = (filename) ->
  console.log filename
  fsplit = filename.split('.')
  fsplit.pop() # pop last part of filename, ext
  fsplit.join('.')

# fNameSrc = './test/docs/otl.ol'
# r = (callback) ->
#   fNameSrc = './test/docs/otl.ol'
#   console.log fs.readFile(fNameSrc)
#   fs.readFile fNameSrc, 'utf8', (callback) ->   
#     console.log  err if err
#     console.log 'read' 
#     callback data

# console.log r()

class Otl
  constructor: (opts) ->
    @rootdir        = opts.rootdir
    @subdir         = opts.subdir
    @srcName        = opts.srcName
    @dstPath        = opts.dstPath
    @basePath       = path.join(@rootdir, @subdir)
    @fNameSrc       = path.join(@basePath, @srcName)
    @fileNameOnly   = stripFileExtension(@srcName)
    @fNameJade      = path.join(@dstPath, @subdir, @fileNameOnly + '.jade')
    @fNameHtml      = path.join(@dstPath, @subdir, @fileNameOnly + '.html')
    @baseIndent     = Array(5).join ' '
    @outL           = []
    @spacesPerlevel = 2
  indentSpaces: (level = 1) ->
    s = ''
    if level > 0
      s = '                                                   '.substr(0, level * @spacesPerlevel)
    s
  parseLines: (srcLinesArray) ->
    currLevel = -1
    outL      = []
    for i of srcLinesArray
      line = srcLinesArray[i]
      heading = (line.replace /^\s+/g, "")
      continue if not heading.length

      level = ((line.length - heading.length) / @spacesPerlevel) + 1

      if level != currLevel
        if level == 1 or currLevel == -1
          level = 1
          outL.push('ul.l1')
          outL.push(@indentSpaces() + 'li.l1')
          outL.push(@indentSpaces(2) + '| ' + heading)
          currLevel = 1

        else if level > currLevel
          level = currLevel = currLevel + 1
          outL.push(@indentSpaces(currLevel + currLevel - 2) + 'ul.l' + level)
          outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li.l' + level)
          outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)

        else # level < currLevel
          currLevel = level
          outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li.l' + level)
          outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)

      else
        outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li.l' + level)
        outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)

    outL
  prependLines: (outL) ->
    jadeStr = '''
  !!! 5
  html
    head
      meta(charset="utf-8")
      link(rel='stylesheet', media='screen', href='/ol.css')
    body(lang='en')

  '''
    # prepend baseIndent for each line
    for line in outL
      jadeStr += @baseIndent + line + "\n"
    jadeStr
  buildJade: (outL) ->
    dirToMk = path.join(@dstPath, @subdir)
    fse.mkdirSync dirToMk
    fs.writeFileSync @fNameJade, @prependLines(outL), 'utf8'
  parse: ->
    data = fs.readFileSync @fNameSrc, 'utf8'
    srcLinesArray = data.toString().split("\n")
    @buildJade @parseLines(srcLinesArray), (err) ->
      return err if err

    #callback console.log 'callback'

exports.Otl = Otl

# exports.parse = (srcPath, dstPath) ->
#   grunt.file.recurse srcPath, (abspath, rootdir, subdir, filename) ->
#     if grunt.file.isMatch('*.ol', filename)
#       # parseOl path.join(rootdir, subdir), filename, dstPath
#       parseOl rootdir, subdir, filename, dstPath