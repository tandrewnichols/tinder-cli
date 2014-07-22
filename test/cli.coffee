colors = require 'colors'

describe 'cli', ->
  Given -> @git = {}
  Given -> @bash = {}
  Given -> @interpolation = {}
  Given -> @cp = {}
  Given -> @async = {}
  Given -> @subject = sandbox '../lib/cli',
    child_process: @cp
    async: @async
    './git': @git
    './bash': @bash
    './interpolation': @interpolation

  describe '.cleanup', ->
    Given -> sinon.spy console, 'log'
    afterEach -> console.log.restore()
    afterEach -> @subject.exit.restore()
    Given -> sinon.stub @subject, 'exit'
    Given -> @bash.rm =
      bind: sinon.stub()
    Given -> @bash.rm.bind.withArgs('foo').returns 'rm foo'
    Given -> @bash.rm.bind.withArgs('bar').returns 'rm bar'

    context 'clean', ->
      Given -> @cp.exec = sinon.stub()
      Given -> @options =
        clean: true
        repoName: 'foo'
        tempDir: 'bar'
      Given -> @async.parallel = sinon.stub()
        
      context 'error', ->
        Given -> @async.parallel.withArgs([ 'rm foo', 'rm bar' ], sinon.match.func).callsArgWith 1, 'an error'
        When -> @subject.cleanup 'How much wood could a wood chuck chuck?', @options
        Then -> expect(@subject.exit).to.have.been.calledWith 1, 'an error'

      context 'no error', ->
        Given -> @async.parallel.withArgs([ 'rm foo', 'rm bar' ], sinon.match.func).callsArgWith 1, null
        When -> @subject.cleanup 'The last lights off the black west went', @options
        Then -> expect(@subject.exit).to.have.been.calledWith 1, 'Removed foo and bar'

    context 'no clean', ->
      Given -> @options =
        clean: false
        repoName: 'foo'
        tempDir: 'footemp'
      When -> @subject.cleanup 'I have measured out my life with coffee spoons', @options
      Then -> expect(@subject.exit).to.have.been.calledWith 1, 'Not removing foo and footemp'.red

  describe '.exit', ->
    afterEach -> console.log.restore()
    afterEach -> process.exit.restore()
    Given -> sinon.spy console, 'log'
    Given -> sinon.stub process, 'exit'
    context 'with code and message', ->
      When -> @subject.exit 6, 'something went horribly awry'
      Then -> expect(console.log).to.have.been.calledWith 'something went horribly awry'
      And -> expect(process.exit).to.have.been.calledWith 6

    context 'no code', ->
      When -> @subject.exit 6
      Then -> expect(process.exit).to.have.been.calledWith()

  describe '.create', ->
    afterEach ->
      @subject.cleanup.restore()
      @subject.exit.restore()
    Given -> sinon.stub @subject, 'cleanup'
    Given -> sinon.stub @subject, 'exit'
    Given -> stubAll @git, ['getGithubUrl', 'clone', 'createRepo', 'init', 'createRemote', 'add', 'commit', 'push']
    Given -> stubAll @bash, ['copy', 'cleanup']
    Given -> stubAll @interpolation, ['find', 'iterate']
    Given -> @options =
      user: 'quux:baz'
    Given -> @async.series = sinon.stub()

    context 'no error', ->
      Given -> @async.series.withArgs([
        'getGithubUrl'
        'clone'
        'copy'
        'find'
        'iterate'
        'createRepo'
        'init'
        'createRemote'
        'add'
        'commit'
        'push'
        'cleanup'
      ], sinon.match.func).callsArgWith 1, null
      When -> @subject.create 'horace-the-horrible', 'tinder-box', 'description', @options
      Then -> expect(@options.repoName).to.equal 'horace-the-horrible'
      And -> expect(@options.template).to.equal 'tinder-box'
      And -> expect(@options.cwd).to.equal './horace-the-horrible'
      And -> expect(@options.description).to.equal 'description'
      And -> expect(@subject.exit).to.have.been.called

    context 'error', ->
      Given -> @options.vars = type: 'foo'
      Given -> @async.series.withArgs([
        'getGithubUrl'
        'clone'
        'copy'
        'find'
        'iterate'
        'createRepo'
        'init'
        'createRemote'
        'add'
        'commit'
        'push'
        'cleanup'
      ], sinon.match.func).callsArgWith 1, 'Hark, an error occurreth!'
      When -> @subject.create 'horace-the-horrible', 'tinder-box', 'description', @options
      Then -> expect(@options.repoName).to.equal 'horace-the-horrible'
      And -> expect(@options.template).to.equal 'tinder-box'
      And -> expect(@options.user).to.equal 'quux'
      And -> expect(@options.pass).to.equal 'baz'
      And -> expect(@options.type).to.equal 'foo'
      And -> expect(@options.cwd).to.equal './horace-the-horrible'
      And -> expect(@options.description).to.equal 'description'
      And -> expect(@subject.cleanup).to.have.been.calledWith 'Hark, an error occurreth!', @options

  xdescribe '.register', ->
    afterEach -> @subject.exit.restore()
    Given -> sinon.stub @subject, 'exit'
    Given -> sinon.stub @utils, 'config'
    Given -> @config = sinon.stub()
    Given -> @utils.config.returns
      fetch: 'fetch'
      update: 'update'
    Given -> @async.auto = sinon.stub()

    context 'error reading config', ->
      Given -> @options = {}
      Given -> @async.auto.withArgs(
        config: 'fetch'
        update: ['config', 'update']
      , sinon.match.func).callsArgWith 1, 'No soup for you!'
      When -> @subject.register @options
      Then -> expect(@subject.exit).to.have.been.calledWith 1, 'No soup for you!'

    context 'no error', ->
      Given -> @options = 'At least we have options'
      Given -> @async.auto.withArgs(
        config: 'fetch'
        update: ['config', 'update']
      , sinon.match.func).callsArgWith 1, null
      When -> @subject.register @options
      Then -> expect(@subject.exit).to.have.been.calledWith()
