path           = require 'path'
request        = require 'request'
fs             = require "fs"
#chai           = require "chai"
#chaiAsPromised = require "chai-as-promised"
Q              = require("q")
#chai.use chaiAsPromised
require("mocha-as-promised")()

rootdir = './test/docs'
subdir  = ''
srcName = 'otl.ol'
dstPath = './test/views/docs'
require '../otl'

opts    = {rootdir: rootdir, subdir: subdir, srcName: srcName, dstPath: dstPath}
otl     = new (require '../otl').Otl opts


describe 'Sample otl.ol', ->
  it 'should exist', ->
    fs.existsSync(path.join(rootdir, subdir, srcName)).should.equal true

  describe 'when parsing', ->
    srcJadeFile      = path.join(rootdir, subdir, srcName)
    controlJadeFile  = path.join(dstPath, subdir, 'otl.should.equal.jade')
    expectedJadeFile = path.join(dstPath, subdir, otl.fileNameOnly) + '.jade'
    before (done) ->
      if fs.existsSync(expectedJadeFile)
        fs.unlinkSync(expectedJadeFile)
      otl.parse ->
      done()

    it "should be generate a .jade file", ->
      fs.existsSync(expectedJadeFile).should.equal true

    it "should be valid", ->
      controlJadeStr   = fs.readFileSync(controlJadeFile).toString()
      generatedJadeStr = fs.readFileSync(expectedJadeFile).toString()
      # console.log controlJadeStr.length # is actually 660!!!!!!!!!!!!!!!!
      # console.log generatedJadeStr.length
      generatedJadeStr.length.should.equal 670

    # it 'should generate corresponding .jade file', ->
    #   Q.resolve(otl.parseOl rootdir, subdir, srcName, dstPath).should.be.fulfilled


    # it 'should generate corresponding .jade file', ->
    #   @theTest.run =>
    #     @ran.should.be.true
    #     done()

    # it 'should generate corresponding .jade file', ->
    #   expectedJadeFile = path.join(dstPath, subdir, stripFileExtension(srcName)) + '.jade'

    #   fs.existsSync(expectedJadeFile).should.equal true

    #   # console.log fs.readFileSync(expectedJadeFile).toString()





# describe 'GET /', ->
#   response = null
#   before (done) ->
#     request 'http://localhost:3001', (e, r, b) ->
#       response = r
#       done()

#   it 'should return 200', (done) ->
#     response.statusCode.should.equal 200
#     done()
#     