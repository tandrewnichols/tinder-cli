EventEmitter = require('events').EventEmitter

describe 'lib/git', ->
  Given -> @cp = {}
  Given -> @request = {}
  Given -> @rand = {}
  Given -> @subject = sandbox '../lib/git',
    child_process: @cp
    request: @request
    randomstring: @rand

  describe '.getGithubUrl', ->
    Given -> @cb = sinon.spy()
    context 'no template', ->
      Given -> @options = {}
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith 'Unable to construct a github url. No template provided.'

    context 'full url', ->
      Given -> @options =
        template: 'git@github.com:foo/bar.git'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith null
      And -> expect(@options.githubUrl).to.equal 'git@github.com:foo/bar.git'

    context 'user/repo', ->
      Given -> @options =
        template: 'foo/bar'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith null
      And -> expect(@options.githubUrl).to.equal 'git@github.com:foo/bar.git'

    context 'repo', ->
      Given -> @options =
        user: 'foo'
        template: 'bar'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith null
      And -> expect(@options.githubUrl).to.equal 'git@github.com:foo/bar.git'

    context 'no user or template', ->
      Given -> @options =
        template: 'foo'
      When -> @subject.getGithubUrl @options, @cb
      Then -> expect(@cb).to.have.been.calledWith 'Unable to construct a github url. The template was not in a known form and no github username was provided.'

  describe '.clone', ->
    Given -> @clone = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['clone', 'git@github.com:foo/bar.git', 'blah'],
      stdio: 'inherit'
    ).returns @clone
    Given -> @rand.generate = sinon.stub()
    Given -> @rand.generate.returns 'blah'
    Given -> @options =
      githubUrl: 'git@github.com:foo/bar.git'

    context 'error', ->
      When -> @subject.clone @options, @cb
      And -> @clone.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git clone git@github.com:foo/bar.git returned code 1'
      And -> expect(@options.tempDir).to.equal './blah'

    context 'no error', ->
      When -> @subject.clone @options, @cb
      And -> @clone.emit('close', 0)
      Then -> expect(@cb).to.have.been.called
      And -> expect(@options.tempDir).to.equal './blah'

  describe '.createRepo', ->
    Given -> @request.post = sinon.stub()
    Given -> @cb = sinon.spy()
    context 'error', ->
      Given -> @request.post.withArgs('https://api.github.com/user/repos',
        json:
          name: 'repo'
          description: 'a repo'
          private: true
          has_wiki: true
          has_issues: true
        auth:
          user: 'theBigFoo'
          pass: 'bigfoo57'
        headers:
          'User-Agent': 'repo'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      Given -> @options =
        user: 'theBigFoo'
        pass: 'bigfoo57'
        repoName: 'repo'
        description: 'a repo'
        private: true
        wiki: true
        issues: true
      When -> @subject.createRepo @options, @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'non-200 response', ->
      Given -> @request.post.withArgs('https://api.github.com/user/repos',
        json:
          name: 'repo'
          description: 'a repo'
          private: true
          has_wiki: true
          has_issues: true
        auth:
          user: 'theBigFoo'
          pass: 'bigfoo57'
        headers:
          'User-Agent': 'repo'
      , sinon.match.func).callsArgWith 2, null,
        statusCode: 418
      , null
      Given -> @options =
        user: 'theBigFoo'
        pass: 'bigfoo57'
        repoName: 'repo'
        description: 'a repo'
        private: true
        wiki: true
        issues: true
      When -> @subject.createRepo @options, @cb
      Then -> expect(@cb).to.have.been.calledWith 'https://api.github.com/user/repos responded with status code 418'

    context 'no error', ->
      context 'private, wiki, issues', ->
        Given -> @request.post.withArgs('https://api.github.com/user/repos',
          json:
            name: 'repo'
            description: 'a repo'
            private: true
            has_wiki: true
            has_issues: true
          auth:
            user: 'theBigFoo'
            pass: 'bigfoo57'
          headers:
            'User-Agent': 'repo'
        , sinon.match.func).callsArgWith 2, null,
          statusCode: 200
        ,
          html_url: 'http://github.com/foo/bar'
          some:
            fake: 'stuff'
          that:
            github: 'returns'
        Given -> @options =
          user: 'theBigFoo'
          pass: 'bigfoo57'
          repoName: 'repo'
          description: 'a repo'
          private: true
          wiki: true
          issues: true
        When -> @subject.createRepo @options, @cb
        Then -> expect(@cb).to.have.been.called
        And -> expect(@options.repo).to.deeply.equal
          html_url: 'http://github.com/foo/bar'
          some:
            fake: 'stuff'
          that:
            github: 'returns'

      context 'no private, wiki, issues', ->
        Given -> @request.post.withArgs('https://api.github.com/user/repos',
          json:
            name: 'repo'
            description: 'a repo'
            private: false
            has_wiki: false
            has_issues: false
          auth:
            user: 'theBigFoo'
            pass: 'bigfoo57'
          headers:
            'User-Agent': 'repo'
        , sinon.match.func).callsArgWith 2, null,
          statusCode: 200
        ,
          html_url: 'http://github.com/pizza/delivery'
          some:
            fake: 'stuff'
          that:
            github: 'returns'
        Given -> @options =
          user: 'theBigFoo'
          pass: 'bigfoo57'
          repoName: 'repo'
          description: 'a repo'
          private: false
          wiki: false
          issues: false
        When -> @subject.createRepo @options, @cb
        Then -> expect(@cb).to.have.been.called
        And -> expect(@options.repo).to.deeply.equal
          html_url: 'http://github.com/pizza/delivery'
          some:
            fake: 'stuff'
          that:
            github: 'returns'

  describe '.init', ->
    Given -> @init = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['init'],
      stdio: 'inherit',
      cwd: './banana'
    ).returns @init
    Given -> @options =
      cwd: './banana'
    
    context 'error', ->
      When -> @subject.init @options, @cb
      And -> @init.emit 'close', 1
      Then -> expect(@cb).to.have.been.calledWith 'git init returned code 1'

    context 'success', ->
      When -> @subject.init @options, @cb
      And -> @init.emit 'close', 0
      Then -> expect(@cb).to.have.been.called

  describe '.createRemote', ->
    Given -> @remote = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['remote', 'add', 'origin', 'git@github.com:tandrewnichols/bobloblaw'],
      stdio: 'inherit'
      cwd: './bobloblaw'
    ).returns @remote
    Given -> @options =
      cwd: './bobloblaw'
      repo:
        clone_url: 'git@github.com:tandrewnichols/bobloblaw'

    context 'error', ->
      When -> @subject.createRemote @options, @cb
      And -> @remote.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git remote add origin git@github.com:tandrewnichols/bobloblaw returned code 1'
      
    context 'success', ->
      When -> @subject.createRemote @options, @cb
      And -> @remote.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

  describe '.add', ->
    Given -> @add = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['add', '.'],
      stdio: 'inherit'
      cwd: './moosen'
    ).returns @add
    Given -> @options =
      cwd: './moosen'

    context 'no error', ->
      When -> @subject.add @options, @cb
      And -> @add.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      When -> @subject.add @options, @cb
      And -> @add.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git add . returned code 1'

  describe '.commit', ->
    Given -> @commit = new EventEmitter()
    Given -> @options =
      cwd: './fuzzy-lovehandles'
      template: 'foo/bar'
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['commit', '-m', 'Initial commit using tinder template foo/bar'],
      stdio: 'inherit'
      cwd: './fuzzy-lovehandles'
    ).returns @commit

    context 'no error', ->
      When -> @subject.commit @options, @cb
      And -> @commit.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      When -> @subject.commit @options, @cb
      And -> @commit.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git commit -m "Initial commit using tinder template foo/bar" returned code 1'

  describe '.push', ->
    Given -> @push = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['push', 'origin', 'master'],
      stdio: 'inherit'
      cwd: './michael-jackson-impersonater'
    ).returns @push
    Given -> @options =
      cwd: './michael-jackson-impersonater'

    context 'no error', ->
      When -> @subject.push @options, @cb
      And -> @push.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      When -> @subject.push @options, @cb
      And -> @push.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git push origin master returned code 1'
