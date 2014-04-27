describe 'utils', ->
  Given -> @request = {}
  Given -> @cp = {}
  Given -> @subject = sandbox '../lib/utils',
    request: @request
    child_process: @cp

  describe '.getGithubUrl', ->
    Given -> @cb = sinon.spy()
    context 'full url', ->
      When -> @subject.getGithubUrl 'git@github.com:foo/bar.git', @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'user/repo', ->
      When -> @subject.getGithubUrl 'foo/bar', @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'repo only', ->
      Given -> @request.get = sinon.stub().withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func)
      context 'npm error', ->
        Given -> @request.get.callsArgWith 1, 'error', null, null
        When -> @subject.getGithubUrl 'bar', @cb
        Then -> expect(@cb).to.have.been.calledWith 'error', null

      context 'npm timeout', ->
        Given -> @request.get.callsArgWith 1, null, null, null
        When -> @subject.getGithubUrl 'bar', @cb
        Then -> expect(@cb).to.have.been.calledWith 'https://registry.npmjs.org timed out processing the request', null

      context 'success', ->
        Given -> @request.get.callsArgWith 1, null, null, {homepage: 'https://github.com/foo/bar'}
        When -> @subject.getGithubUrl 'bar', @cb
        Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

  describe '.clone', ->
    afterEach ->
      process.chdir.restore()
    Given -> @cb = sinon.spy()
    Given -> sinon.spy process, 'chdir'
    Given -> @cp.exec = sinon.stub().withArgs 'git clone git@github.com:foo/bar.git pizza', sinon.match.func

    context 'error', ->
      Given -> @cp.exec.callsArgWith 1, 'error', null, null
      When -> @subject.clone
        cloneUrl: 'git@github.com:foo/bar.git'
        repoName: 'pizza'
      , @cb
      Then -> expect(@cb).to.have.been.calledWith 'error', null
