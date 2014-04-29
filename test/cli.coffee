colors = require 'colors'

describe 'cli', ->
  Given -> @utils = {}
  Given -> @cp = {}
  Given -> @subject = sandbox '../lib/cli',
    child_process: @cp
    './utils': @utils

  describe '.cleanup', ->
    Given -> sinon.stub console, 'log'
    afterEach ->
      console.log.restore()
    context 'clean', ->
      afterEach ->
        @subject.exit.restore()
      Given -> sinon.stub @subject, 'exit'
      Given -> @cp.exec = sinon.stub()
      Given -> @options =
        clean: true
        repoName: 'foo'
      context 'err', ->
        afterEach ->
          process.chdir.restore()
          process.cwd.restore()
        Given -> sinon.stub process, 'chdir'
        Given -> sinon.stub(process, 'cwd').returns '/blah/blah/foo'
        Given -> @cp.exec.withArgs('rm -rf foo', sinon.match.func).callsArgWith 1, 'err', null, null
        When -> @subject.cleanup 'How much wood could a wood chuck chuck?', @options
        Then -> expect(@subject.exit).to.have.been.calledWith 1, 'err'

      context 'stderr', ->
        afterEach ->
          process.cwd.restore()
        Given -> sinon.stub(process, 'cwd').returns '/blah/blah/blah'
        Given -> @cp.exec.callsArgWith 1, null, null, 'stderr'
        When -> @subject.cleanup 'She sells sea shells', @options
        Then -> expect(@subject.exit).to.have.been.calledWith 1, 'stderr'

      context 'no error', ->
        afterEach ->
          process.cwd.restore()
        Given -> sinon.stub(process, 'cwd').returns '/blah/blah/blah'
        Given -> @cp.exec.callsArgWith 1, null, 'stdout', null
        When -> @subject.cleanup 'The last lights of the black west went', @options
        Then -> expect(@subject.exit).to.have.been.calledWith 1, 'Removed foo'

    context 'no clean', ->
      afterEach ->
        @subject.exit.restore()
      Given -> sinon.stub @subject, 'exit'
      Given -> @options =
        clean: false
        repoName: 'foo'
      When -> @subject.cleanup 'I have measured out my life with coffee spoons', @options
      Then -> expect(@subject.exit).to.have.been.calledWith 1, 'Not removing ./foo'.red

  describe '.create', ->

