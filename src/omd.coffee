path      = require 'path'
fs        = require 'fs'
fse       = require 'fs-extra' # https://npmjs.org/package/fs-extra
grunt     = require "grunt" # https://github.com/cowboy/grunt

stripFileExtension = (filename) ->
  fsplit = filename.split('.')
  fsplit.pop() # pop last part of filename, ext
  fsplit.join('.')

# fNameSrc = './test/docs/omd.ol'
# r = (callback) ->
#   fNameSrc = './test/docs/omd.ol'
#   console.log fs.readFile(fNameSrc)
#   fs.readFile fNameSrc, 'utf8', (callback) ->   
#     console.log  err if err
#     console.log 'read' 
#     callback data

# console.log r()

class Omd
  constructor: ->
    @regExpLinks    = /\b((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$])/ig
    @srcName        = null
    @dstName        = null
    @baseIndent     = Array(5).join ' '
    @outL           = []
    @spacesPerlevel = 2
  indentSpaces: (level = 1) ->
    s = ''
    if level > 0
      s = '                                                   '.substr(0, level * @spacesPerlevel)
    s
  firstNonSpacePosition: (str) ->
    strLeftTrimmed = (str.replace /^\s+/g, "")
    0 if not strLeftTrimmed.length
    str.length - strLeftTrimmed.length
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
    fse.mkdirSync @dstPath
    fs.writeFileSync @dstName, @prependLines(outL), 'utf8'

  parseMarkdown: (outL) ->
    i = 0
    while i < outL.length
      line = outL[i]
      match = @regExpLinks.exec line
      if match
        # console.log '-----------------------'
        # console.log 'match', match[0]
        # console.log @firstNonSpacePosition line
        spaces = @baseIndent + Array(@firstNonSpacePosition(line) + 1).join(' ')
        line = line.replace @regExpLinks, "\n#{spaces}a(href=\"$1\") $1\n#{spaces}| "
        # console.log
        # console.log line
        # console.log '-----------------------'
        outL[i] = line
      i++

    return outL


  parse: (@srcName, @dstPath, callback) ->
    # console.log 'parse', @srcName, @dstPath
    # get filename only
    filename = @srcName.split(path.sep).pop()
    # need srcName without extension
    # I know that the extension is .omd right!
    @dstName = path.join(@dstPath, filename.substr(0, filename.length-4) + '.jade')
    data = fs.readFileSync @srcName, 'utf8'
    srcLinesArray = data.toString().split("\n")
    @buildJade @parseMarkdown(@parseLines(srcLinesArray)), (err) ->
      return err if err

    callback()

  buildIndex: (basePath, srcPath, dstPath, callback) ->
    files = []
    jadeStr = ''
    @crawlForFiles srcPath, (callback) ->
      # console.log 'crawlForFiles'
      # callback
      files = callback

    return null if not files

    jadeStr = '''
      extends ../layout

      block content
        h1= title
        ul
      '''    

    for file in files
      fPath = file.fPath
      jadeStr += '    '
      jadeStr += "\n    li\n      a(href=\"#{basePath}/#{fPath}\") #{fPath}"

    jadeFile = path.join(dstPath, 'index.jade')

    fse.mkdirSync dstPath
    fs.writeFileSync jadeFile, jadeStr, 'utf8'
    callback
  crawlForFiles: (@srcPath, callback) ->
    files = []
    grunt.file.recurse @srcPath, (abspath, rootdir, subdir, fileName) ->
      if grunt.file.isMatch('*.omd', fileName)
        files.push 
          subdir: subdir
          fName: fileName
          fPath: path.join(subdir, fileName.substr(0, fileName.length-4)).replace /\\/g, "/"
    callback files

exports.Omd = Omd