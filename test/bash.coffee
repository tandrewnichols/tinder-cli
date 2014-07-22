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
      tempDir: 'furby'
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('cp', ['-Ri', 'furby/template', 'world'],
      stdio: 'inherit'
    ).returns @copy

    context 'error', ->
      When -> @subject.copy @options, @cb, {}
      And -> @copy.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'cp -Ri furby/template world returned code 1'

    context 'no error', ->
      When -> @subject.copy @options, @cb, {}
      And -> @copy.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

  describe '.cleanup', ->
    afterEach -> @subject.rm.restore()
    Given -> sinon.stub @subject, 'rm'
    Given -> @next = sinon.stub()
    When -> @subject.cleanup { tempDir: 'banana' }, @next
    Then -> expect(@subject.rm).to.have.been.calledWith 'banana', @next

  describe '.rm', ->
    Given -> @rm = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('rm', ['-rf', 'neverland'],
      stdio: 'inherit'
    ).returns @rm

    context 'error', ->
      When -> @subject.rm 'neverland', @cb
      And -> @rm.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'rm -rf neverland returned code 1'

    context 'no error', ->
      When -> @subject.rm 'neverland', @cb
      And -> @rm.emit('close', 0)
      Then -> expect(@cb).to.have.been.called
