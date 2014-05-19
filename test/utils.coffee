EventEmitter  = require('events').EventEmitter
colors = require 'colors'
fs = require 'fs'
_ = require 'underscore'

describe 'utils', ->
  Given -> @request = {}
  Given -> @cp = {}
  Given -> @fs = {}
  Given -> @async = {}
  Given -> @subject = sandbox '../lib/utils',
    request: @request
    child_process: @cp
    fs: @fs
    async: @async

  describe '.getGithubUrl', ->
    Given -> @cb = sinon.spy()
    context 'full url', ->
      Given -> @options =
        template: 'git@github.com:foo/bar.git'
      When -> @waterfallFn = @subject.getGithubUrl @options
      And -> @waterfallFn @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'user/repo', ->
      Given -> @options =
        template: 'foo/bar'
      When -> @waterfallFn = @subject.getGithubUrl @options
      And -> @waterfallFn @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'repo', ->
      Given -> @request.get = sinon.stub()
      Given -> @options =
        template: 'bar'
      context 'npm error', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, 'error', null, null
        When -> @waterfallFn = @subject.getGithubUrl @options
        And -> @waterfallFn @cb
        Then -> expect(@cb).to.have.been.calledWith 'error', null

      context 'npm timeout', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null, null, null
        When -> @waterfallFn = @subject.getGithubUrl @options
        And -> @waterfallFn @cb
        Then -> expect(@cb).to.have.been.calledWith 'https://registry.npmjs.org timed out processing the request', null

      context 'success', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null, null, {homepage: 'https://github.com/foo/bar'}
        When -> @waterfallFn = @subject.getGithubUrl @options
        And -> @waterfallFn @cb
        Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

  describe '.clone', ->
    afterEach ->
      process.chdir.restore()
      console.log.restore()
    Given -> @cb = sinon.spy()
    Given -> sinon.stub process, 'chdir'
    Given -> sinon.spy console, 'log'
    Given -> @cp.exec = sinon.stub()
    Given -> @options =
      repoName: 'pizza'

    context 'error', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza', sinon.match.func).callsArgWith 1, 'error', null, null
      When -> @waterfallFn = @subject.clone @options
      And -> @waterfallFn 'git@github.com:foo/bar.git', @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza', sinon.match.func).callsArgWith 1, null, 'content', null
      When -> @waterfallFn = @subject.clone @options
      And -> @waterfallFn 'git@github.com:foo/bar.git', @cb
      Then -> expect(@cb).to.have.been.calledWith null
      And -> expect(console.log).to.have.been.calledWith 'Created pizza'.green
      And -> expect(process.chdir).to.have.been.calledWith 'pizza'

    context 'stderr', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza', sinon.match.func).callsArgWith 1, null, null, 'stderr'
      When -> @waterfallFn = @subject.clone @options
      And -> @waterfallFn 'git@github.com:foo/bar.git', @cb
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

  describe '.findInterpolation', ->
    Given -> @cb = sinon.spy()
    Given -> @grep = new EventEmitter()
    Given -> @grep.stdout = new EventEmitter()
    Given -> @cp.spawn = sinon.stub()
    Given -> @options =
      interpolate: 'foo'
      escape: 'bar'
      evaluate: 'baz'
    Given -> @cp.spawn.withArgs('grep', ['-rlP', 'foo|baz|bar', '.']).returns @grep
    When -> @waterfallFn = @subject.findInterpolation @options
    And -> @waterfallFn @cb
    And -> @grep.stdout.emit 'data', 'foo\nbar\nbaz'
    And -> @grep.emit 'close'
    Then -> expect(@cb).to.have.been.calledWith null, ['foo', 'bar', 'baz']

  describe '.replaceInterpolation', ->
    Given -> @next = sinon.spy()
    Given -> @async.each = sinon.stub()
    Given -> @cb = (err) =>
      @async.each.getCall(0).args[2](err)
    Given -> @async.each.withArgs(['./foo', './bar'], sinon.match.func, sinon.match.func).callsArgWith 1, './foo', @cb

    context 'error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ @subject.read, @subject.replace, @subject.write ], sinon.match.func).callsArgWith 1, 'error'
      When -> @waterfallFn = @subject.replaceInterpolation @options
      And -> @waterfallFn ['./foo', './bar'], @next
      Then -> expect(@next).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ @subject.read, @subject.replace, @subject.write ], sinon.match.func).callsArgWith 1, null
      When -> @waterfallFn = @subject.replaceInterpolation @options
      And -> @waterfallFn ['./foo', './bar'], @next
      Then -> expect(@next).to.have.been.calledWith()

  describe '.read', ->
    Given -> @cb = sinon.spy()
    Given -> @fs.readFile = sinon.stub()
    context 'error', ->
      Given -> @fs.readFile.withArgs('./foo', sinon.match.func).callsArgWith 1, 'error', null
      When -> @subject.read './foo', @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @fs.readFile.withArgs('./foo', sinon.match.func).callsArgWith 1, null, 'data'
      When -> @subject.read './foo', @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'data'

  describe '.replace', ->
    Given -> @cb = sinon.spy()
    Given -> @options =
      interpolate: _.templateSettings.interpolate.source
      evaluate: _.templateSettings.evaluate.source
      escape: _.templateSettings.escape.source
      vars:
        repoName: 'xanadu'
        data: 'words'
        replacement: 'monkey'
    When -> @waterfallFn = @subject.replace @options
    And -> @waterfallFn 'some <%= data %> we found in <%= repoName %>', @cb
    And -> console.log @cb.getCall(0).args
    Then -> expect(@cb).to.have.been.calledWith null, 'some words we found in xanadu'

  describe '.write', ->



    #Given -> @fs.readFile = sinon.stub()
    #Given -> @fs.writeFile = sinon.stub()
    #Given -> @fs.readFile.withArgs('./foo', sinon.match.func).callsArgWith 1, null, 'some <{data}>: we found in <{repoName}>'
    #Given -> @fs.writeFile.withArgs('./foo', 'some words we found in xanadu', sinon.match.func).callsArgWith 1, null
    #Given -> @fs.readFile.withArgs('./bar', sinon.match.func).callsArgWith 1, null, 'a better <{replacement}>'
    #Given -> @fs.writeFile.withArgs('./bar', 'a better monkey', sinon.match.func).callsArgWith 1, null
    #Given -> @options =
      #repoName: 'xanadu'
      #vars:
        #data: 'words'
        #replacement: 'monkey'
      #Given -> @fs.readFile.withArgs('./bar', sinon.match.func).callsArgWith 1, 'error', null
      #Given -> @fs.writeFile.withArgs('./bar', 'a better monkey', sinon.match.func).callsArgWith 1, null
