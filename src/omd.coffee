path      = require 'path'
fs        = require 'fs'
fse       = require 'fs-extra' # https://npmjs.org/package/fs-extra
grunt     = require "grunt" # https://github.com/cowboy/grunt
highlight = require('pygments').colorize

String::tolower = -> @toLowerCase()
String::toupper = -> @toUpperCase()
String::ltrim   = -> @.replace /^\s+/g, ""
String::repeat  = (count) -> Array(count).join @
indent          = (level, spacesPerLevel = 2) -> ' '.repeat(level * spacesPerLevel)

pyg    = require("pygments")

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

# highlight = (str, lang, fmt, data) ->
#   console.log 'highlight', fmt
#   console.log data
  

# highlight "puts \"Hello World\"", "ruby", "console", (data) ->
#   console.log data

class Omd
  constructor: ->
    #@regExpLinks    = /\b((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$])/ig
    @regExpLinks    = /(\[(.*?)\]\(((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$])\)|\b((https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$]))/ig
    @srcName        = null
    @dstName        = null
    @baseIndent     = Array(5).join ' '
    @outL           = []
    @spacesPerlevel = 2
    @cssFile        = '/stylesheets/omd.css'
    @inACodeBlock   = 0 # level of code block tag, 0 == false
  indentSpaces: (level = 1) ->
    s = ''
    if level > 0
      s = '                                                   '.substr(0, level * @spacesPerlevel)
    s
  firstNonSpacePosition: (str) ->
    strLeftTrimmed = (str.replace /^\s+/g, "")
    0 if not strLeftTrimmed.length
    str.length - strLeftTrimmed.length
  

  parseHeadingStyle: (heading, level, levelStyles) ->
    ###
    If a heading/line begins with # followed by o or u (order/unorder), then
    use it to style THAT level. It must be the first such mark for THAT level.
    ###
    strLevel = level + '' # need as string

    # are we in a code block?
    # for example if level 3 is a code block tag, then level 4 and deeper is code
    # This will remain so until level returns back to level 3
    if heading[0] == '#' and heading[1] in 'oOuU'
      levelStyles[strLevel] = "#{heading[1]}l"
      # strip out markdown tag
      heading = heading.substr(2).ltrim()
      @inACodeBlock = 0
    else if heading[0..2] == '```'
      @inACodeBlock = level
      heading = ''
      levelStyles[strLevel] = "pre"
      levelStyles[(level+1)+''] = ""
    else
      levelStyles[strLevel] = "ul"  
      @inACodeBlock = 0

    {heading: heading, level: level, levelStyles: levelStyles}

  parseLines: (srcLinesArray) ->
    currLevel = -1
    levelStyles    = {}
    outL      = []
    for i of srcLinesArray
      line              = srcLinesArray[i]
      heading           = (line.replace /^\s+/g, "")
      emitLevelStyleTag = true
      continue if not heading.length

      level = ((line.length - heading.length) / @spacesPerlevel) + 1

      if @inACodeBlock and level > @inACodeBlock
        outL.push(@indentSpaces() + @indentSpaces(currLevel + currLevel - 2) + '| ' + line.substr(@inACodeBlock * @spacesPerlevel))
        continue
      else if @inACodeBlock and level <= @inACodeBlock
        @inACodeBlock = 0
        emitLevelStyleTag = false
        currLevel = level - 2

      if level != currLevel
        if level == 1 or currLevel == -1
          level            = 1
          
          # better way to do this? Like python?!!!!!
          headingInfo      = @parseHeadingStyle heading, level, levelStyles
          heading          = headingInfo.heading
          level            = headingInfo.level
          levelStyles      = headingInfo.levelStyles

          
          if not @inACodeBlock
            outL.push("#{levelStyles['1']}") if emitLevelStyleTag
            outL.push(@indentSpaces() + 'li')
            outL.push(@indentSpaces(2) + '| ' + heading)
          else
            outL.push("#{levelStyles['1']} " + heading)
            #outL.push(@indentSpaces(2) + '| ' + heading)
          
          currLevel = 1

        else if level > currLevel
          level                 = currLevel = currLevel + 1
          headingInfo           = @parseHeadingStyle heading, level, levelStyles
          heading               = headingInfo.heading
          level                 = headingInfo.level
          levelStyles           = headingInfo.levelStyles
          
          if not @inACodeBlock
            outL.push(@indentSpaces(currLevel + currLevel - 2) + "#{levelStyles[level]}") if emitLevelStyleTag
            outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li')
            outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)
            # currLevel -= 1
          else
            outL.push(@indentSpaces(currLevel + currLevel - 2) + "#{levelStyles[level]} " + heading) if emitLevelStyleTag

          


        else # level < currLevel
          currLevel = level
          outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li')
          outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)

      else
        outL.push(@indentSpaces(currLevel + currLevel - 1) + 'li')
        outL.push(@indentSpaces(currLevel + currLevel) + '| ' + heading)

    outL
  prependLines: (outL) ->
    # pygCode = ''
    # pyg.colorize "puts 'Hello World!'", "ruby", "console", (data) ->
    #   pygCode = data
    #   console.log data

    # console.log 'pygCode' + pygCode + 'end'
    # highlight "puts \"Hello World\"", "ruby", "console", (data) ->
    #   console.log data

    # code = """
    #   highlight('/home/pkumar/package.json', null, 'html', function(data) {
    #     console.log(data);
    #   });
    # """
    # highlight code, null, "html", ((data) ->
    #   hcode = data
    # ),
    #   force: true

    # console.log hcode
    jadeStr = """
      !!! 5
      html
        head
          meta(charset="utf-8")
          link(rel='stylesheet', media='screen', href='#{@cssFile}')
        body(lang='en')
          a(href="/") Home | 
          a(href="/docs") Docs

      """
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
        # match[2] > '' means it is a link like [GitHub](http://github.com)
        if match[2]
          linkTitle = match[2]
          linkUrl = match[3]
        else
          linkTitle = match[1]
          linkUrl = match[1]

        # console.log '-----------------------'
        # console.log 'match', match[0]
        # console.log @firstNonSpacePosition line
        spaces = @baseIndent + Array(@firstNonSpacePosition(line) + 1).join(' ')
        line = line.replace @regExpLinks, "\n#{spaces}a(href=\"#{linkUrl}\") #{linkTitle}\n#{spaces}| "
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
        a(href="/") Home
        ul
      '''    

    for file in files
      fPath = file.fPath
      jadeStr += '    '
      jadeStr += "\n    li\n      a(href=\"/#{basePath}/#{fPath}\") #{fPath}"

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