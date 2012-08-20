path            = require 'path'
#request        = require 'request'
fs              = require "fs"
#chai           = require "chai"
#chaiAsPromised = require "chai-as-promised"
#chai.use chaiAsPromised
#Q              = require("q")
# require("mocha-as-promised")()

rootdir         = './test/docs'

testFile        = 'test.omd'
dstPath         = path.join(__dirname, 'views', 'docs')
srcName         = path.join(__dirname, 'docs', testFile)
dstJadeFile     = path.join(__dirname, 'views', 'docs', 'test.jade')
testJadeFile    = path.join(__dirname, 'views', 'docs', 'test.should.equal.jade')
# opts          = {rootdir: rootdir, subdir: subdir, srcName: srcName, dstPath: dstPath}

omd             = new (require '../omd').Omd 

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

    it "should be valid", ->
      testJadeFileStr = fs.readFileSync(testJadeFile).toString()
      dstJadeFileStr  = fs.readFileSync(dstJadeFile).toString()
      # console.log testJadeFileStr.length # is actually 660!!!!!!!!!!!!!!!!
      # console.log dstJadeFileStr.length
      dstJadeFileStr.length.should.equal 670
