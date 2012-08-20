path            = require 'path'
#request        = require 'request'
fs              = require "fs"
#chai           = require "chai"
#chaiAsPromised = require "chai-as-promised"
#chai.use chaiAsPromised
#Q              = require("q")
# require("mocha-as-promised")()

testFile     = 'test.omd'
srcBasePath  = 'docs'
srcPath      = path.join(__dirname, 'docs')
srcName      = path.join(srcPath, testFile)
dstPath      = path.join(__dirname, 'views', 'docs')
dstJadeFile  = path.join(dstPath, 'test.jade')
dstIndexFile = path.join(dstPath, 'index.jade')
testJadeFile = path.join(dstPath, 'test.should.equal.jade')

omd          = new (require '../omd').Omd 

describe 'When crawling for files', ->
  before (done) ->
    if fs.existsSync(dstIndexFile)
      fs.unlinkSync(dstIndexFile)
    done()

  # before (done) ->
  #   omd.crawlForFiles srcPath, (callback) ->
  #   done()

  it "should return a valid array of found files", ->
    #console.log 
    testStr = ''
    omd.crawlForFiles srcPath, (callback) ->
      files = callback
      for file in files
        #console.log file.fPath
        testStr += file.fPath

      testStr.should.equal 'd1/d1-ad1/d1-bd1/d11/d11-ad1/d11/d11-bd1/d12/d12-ad1/d12/d12-bd1/d12/d121/d121-atest'

  it "should create a .jade file with listing of all .oml documents", ->
    omd.buildIndex srcBasePath, srcPath, dstPath, (callback) ->
      fs.existsSync(dstIndexFile).should.equal true

describe 'Sample ' + testFile, ->
  before (done) ->
    if fs.existsSync(dstJadeFile)
      fs.unlinkSync(dstJadeFile)
    done()

  describe 'when parsing', ->
    before (done) ->
      omd.parse srcName, dstPath, (callback) ->
      done()

    it "should be generate a .jade file", ->
      fs.existsSync(dstJadeFile).should.equal true

    # it "should be valid", ->
    #   testJadeFileStr = fs.readFileSync(testJadeFile).toString()
    #   dstJadeFileStr  = fs.readFileSync(dstJadeFile).toString()
    #   # console.log testJadeFileStr.length # is actually 660!!!!!!!!!!!!!!!!
    #   # console.log dstJadeFileStr.length
    #   dstJadeFileStr.length.should.equal 670
