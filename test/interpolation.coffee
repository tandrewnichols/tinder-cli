describe 'lib/interpolation', ->
  Given -> @fs = {}
  Given -> @cp = {}
  Given -> @subject = sandbox '../lib/interpolation',
    fs: @fs
    cp: @cp

  describe '.findInterpolation', ->
    Given -> @cb = sinon.spy()
    Given -> @grep = new EventEmitter()
    Given -> @grep.stdout = new EventEmitter()
    Given -> @cp.spawn = sinon.stub()
    Given -> @options =
      cwd: './six-toed-sloth'
      interpolate: 'foo'
      escape: 'bar'
      evaluate: 'baz'
    Given -> @cp.spawn.withArgs('grep', ['-rlP', 'foo|baz|bar', './six-toed-sloth']).returns @grep
    When -> @subject.findInterpolation @options, @cb
    And -> @grep.stdout.emit 'data', 'foo\nbar\nbaz'
    And -> @grep.emit 'close'
    Then -> expect(@cb).to.have.been.calledWith null, ['foo', 'bar', 'baz']

  describe '.replaceInterpolation', ->
    afterEach -> @subject.replace.restore()
    Given -> sinon.stub @subject, 'replace'
    Given -> @subject.replace.returns
      read: 'read'
      replace: 'replace'
      write: 'write'
    Given -> @next = sinon.spy()
    Given -> @async.each = sinon.stub()
    Given -> @cb = (err) =>
      @async.each.getCall(0).args[2](err)
    Given -> @async.each.withArgs(['./foo', './bar'], sinon.match.func, sinon.match.func).callsArgWith 1, './foo', @cb

    context 'error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ 'read', 'replace', 'write' ], sinon.match.func).callsArgWith 1, 'error'
      When -> @subject.replaceInterpolation {}, @next,
        findInterpolation: ['./foo', './bar']
      Then -> expect(@next).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ 'read', 'replace', 'write' ], sinon.match.func).callsArgWith 1, null
      When -> @subject.replaceInterpolation {}, @next,
        findInterpolation: ['./foo', './bar']
      Then -> expect(@next).to.have.been.calledWith()

  describe '.read', ->
    Given -> @cb = sinon.spy()
    Given -> @fs.readFile = sinon.stub()
    context 'error', ->
      Given -> @fs.readFile.withArgs('./foo', 'utf8', sinon.match.func).callsArgWith 2, 'error', null
      When -> @subject.read './foo', {}, @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @fs.readFile.withArgs('./foo', 'utf8', sinon.match.func).callsArgWith 2, null, 'data'
      When -> @subject.read './foo', {}, @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'data'

  describe '.replace', ->
    Given -> @cb = sinon.spy()
    Given -> @options =
      interpolate: _.templateSettings.interpolate.source
      evaluate: _.templateSettings.evaluate.source
      escape: _.templateSettings.escape.source
      repoName: 'xanadu'
      data: 'words'
      replacement: 'monkey'
    When -> @subject.replace './foo', @options, 'some <%= data %> we found in <%= repoName %>', @cb
    Then -> expect(@cb).to.have.been.calledWith null, 'some words we found in xanadu'

  describe '.write', ->
    Given -> @next = sinon.spy()
    Given -> @fs.writeFile = sinon.stub()
    context 'no error', ->
      Given -> @fs.writeFile.withArgs('./foo', 'a better monkey', sinon.match.func).callsArgWith 2, null
      When -> @subject.write './foo', {}, 'a better monkey', @next
      Then -> expect(@next).to.have.been.calledWith null

    context 'error', ->
      Given -> @fs.writeFile.withArgs('./foo', 'a better monkey', sinon.match.func).callsArgWith 2, 'error'
      When -> @subject.write './foo', {}, 'a better monkey', @next
      Then -> expect(@next).to.have.been.calledWith 'error'
