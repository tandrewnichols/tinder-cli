colors = require 'colors'

describe 'cli', ->
  Given -> @utils = {}
  Given -> @cp = {}
  Given -> @async = {}
  Given -> @subject = sandbox '../lib/cli',
    child_process: @cp
    './utils': @utils
    async: @async

  describe '.cleanup', ->
    Given -> sinon.spy console, 'log'
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

  describe '.exit', ->
    afterEach ->
      console.log.restore()
      process.exit.restore()
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
      @utils.create.restore()
    Given -> sinon.stub @subject, 'cleanup'
    Given -> sinon.stub @subject, 'exit'
    Given -> sinon.stub @utils, 'create'
    Given -> @utils.create.returns
      getGithubUrl: 'getGithubUrl'
      clone: 'clone'
      copy: 'copy'
      findInterpolation: 'findInterpolation'
      replaceInterpolation: 'replaceInterpolation'
      createRepo: 'createRepo'
      createRemote: 'createRemote'
      add: 'add'
      commit: 'commit'
      push: 'push'
      cleanup: 'cleanup'
    Given -> @options =
      description: 'code piece'
      user: 'quux:baz'
    Given -> @async.auto = sinon.stub()

    context 'no error', ->
      Given -> @async.auto.withArgs(
        getGithubUrl: 'getGithubUrl'
        clone: ['getGithubUrl', 'clone']
        copy: ['clone', 'copy']
        findInterpolation: ['copy', 'findInterpolation']
        replaceInterpolation: ['findInterpolation', 'replaceInterpolation']
        createRepo: 'createRepo'
        createRemote: ['copy', 'createRepo', 'createRemote']
        add: ['replaceInterpolation', 'createRemote', 'add']
        commit: ['add', 'commit']
        push: ['commit', 'push']
        cleanup: ['copy', 'cleanup']
      , sinon.match.func).callsArgWith 1, null
      When -> @subject.create 'horace-the-horrible', 'tinder-box', @options
      Then -> expect(@options.repoName).to.equal 'horace-the-horrible'
      And -> expect(@options.template).to.equal 'tinder-box'
      And -> expect(@options.cwd).to.equal './horace-the-horrible'
      And -> expect(@subject.exit).to.have.been.called

    context 'error', ->
      Given -> @options.vars = type: 'foo'
      Given -> @async.auto.withArgs(
        getGithubUrl: 'getGithubUrl'
        clone: ['getGithubUrl', 'clone']
        copy: ['clone', 'copy']
        findInterpolation: ['copy', 'findInterpolation']
        replaceInterpolation: ['findInterpolation', 'replaceInterpolation']
        createRepo: 'createRepo'
        createRemote: ['copy', 'createRepo', 'createRemote']
        add: ['replaceInterpolation', 'createRemote', 'add']
        commit: ['add', 'commit']
        push: ['commit', 'push']
        cleanup: ['copy', 'cleanup']
      , sinon.match.func).callsArgWith 1, 'Hark, an error occurreth!'
      When -> @subject.create 'horace-the-horrible', 'tinder-box', @options
      Then -> expect(@options.repoName).to.equal 'horace-the-horrible'
      And -> expect(@options.template).to.equal 'tinder-box'
      And -> expect(@options.user).to.equal 'quux'
      And -> expect(@options.pass).to.equal 'baz'
      And -> expect(@options.type).to.equal 'foo'
      And -> expect(@options.cwd).to.equal './horace-the-horrible'
      And -> expect(@subject.cleanup).to.have.been.calledWith 'Hark, an error occurreth!', @options
