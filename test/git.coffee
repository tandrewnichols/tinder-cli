describe '.git', ->
  describe '.getGithubUrl', ->
    Given -> @cb = sinon.spy()
    context 'full url', ->
      Given -> @options =
        template: 'git@github.com:foo/bar.git'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'user/repo', ->
      Given -> @options =
        template: 'foo/bar'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'repo', ->
      Given -> @request.get = sinon.stub()
      Given -> @options =
        template: 'bar'
        user: 'foo'
      context 'npm error', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, 'error', null, null
        When -> @subject.getGithubUrl @options, @cb
        Then -> expect(@cb).to.have.been.calledWith 'error', null

      context 'non-200', ->
        context '404', ->
          Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null,
            statusCode: 404
          , {}
          When -> @subject.getGithubUrl @options, @cb
          Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

        context 'non-404', ->
          Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null,
            statusCode: 401
          , {}
          When -> @subject.getGithubUrl @options, @cb
          Then -> expect(@cb).to.have.been.calledWith 'https://registry.npmjs.org/bar/latest responded with status code 401', null

      context '200', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null,
          statusCode: 200
        ,
          homepage: 'https://github.com/foo/bar'
        When -> @subject.getGithubUrl @options, @cb
        Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'
