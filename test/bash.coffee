EventEmitter = require('events').EventEmitter

describe 'lib/bash', ->
  Given -> @cp = {}
  Given -> @subject = sandbox '../lib/bash',
    child_process: @cp
  describe '.copy', ->
    Given -> @copy = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @options =
      repoName: 'world'
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('cp', ['-Ri', 'hello/template', 'world'],
      stdio: 'inherit'
    ).returns @copy

    context 'error', ->
      When -> @subject.copy @options, @cb,
        getGithubUrl: 'git@github.com:say/hello.git'
      And -> @copy.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'cp -Ri hello/template world returned code 1'
      And -> expect(@options.clonedDir).to.equal 'hello'

    context 'no error', ->
      When -> @subject.copy @options, @cb,
        getGithubUrl: 'git@github.com:say/hello.git'
      And -> @copy.emit('close', 0)
      Then -> expect(@cb).to.have.been.called
      And -> expect(@options.clonedDir).to.equal 'hello'

  describe '.cleanup', ->
    Given -> @rm = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('rm', ['-rf', 'neverland'],
      stdio: 'inherit'
    ).returns @rm
    Given -> @options =
      clonedDir: 'neverland'

    context 'error', ->
      When -> @subject.cleanup @options, @cb
      And -> @rm.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'Unable to delete temporary directory ./neverland'

    context 'no error', ->
      When -> @subject.cleanup @options, @cb
      And -> @rm.emit('close', 0)
      Then -> expect(@cb).to.have.been.called
