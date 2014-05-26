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
      When -> @fn = @subject.create @options
      And -> @fn.getGithubUrl @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'user/repo', ->
      Given -> @options =
        template: 'foo/bar'
      When -> @fn = @subject.create @options
      And -> @fn.getGithubUrl @cb
      Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

    context 'repo', ->
      Given -> @request.get = sinon.stub()
      Given -> @options =
        template: 'bar'
      context 'npm error', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, 'error', null, null
        When -> @fn = @subject.create @options
        And -> @fn.getGithubUrl @cb
        Then -> expect(@cb).to.have.been.calledWith 'error', null

      context 'npm timeout', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null, null, null
        When -> @fn = @subject.create @options
        And -> @fn.getGithubUrl @cb
        Then -> expect(@cb).to.have.been.calledWith 'https://registry.npmjs.org timed out processing the request', null

      context 'success', ->
        Given -> @request.get.withArgs('https://registry.npmjs.org/bar/latest', sinon.match.func).callsArgWith 1, null, null, {homepage: 'https://github.com/foo/bar'}
        When -> @fn = @subject.create @options
        And -> @fn.getGithubUrl @cb
        Then -> expect(@cb).to.have.been.calledWith null, 'git@github.com:foo/bar.git'

  describe '.clone', ->
    Given -> @cb = sinon.spy()
    Given -> @cp.exec = sinon.stub()
    Given -> @options =
      repoName: 'pizza'
      cwd: './pizza'
    Given -> @fn = @subject.create @options

    context 'error', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza',
        stdio: 'inherit'
        cwd: './pizza'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      When -> @fn.clone @cb,
        getGithubUrl: 'git@github.com:foo/bar.git'
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza',
        stdio: 'inherit'
        cwd: './pizza'
      , sinon.match.func).callsArgWith 2, null, 'content', null
      When -> @fn.clone @cb,
        getGithubUrl: 'git@github.com:foo/bar.git'
      Then -> expect(@cb).to.have.been.calledWith null

    context 'stderr', ->
      Given -> @cp.exec.withArgs('git clone git@github.com:foo/bar.git pizza',
        stdio: 'inherit'
        cwd: './pizza'
      , sinon.match.func).callsArgWith 2, null, null, 'stderr'
      When -> @fn.clone @cb,
        getGithubUrl: 'git@github.com:foo/bar.git'
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

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
    Given -> @fn = @subject.create @options
    Given -> @cp.spawn.withArgs('grep', ['-rlP', 'foo|baz|bar', './six-toed-sloth']).returns @grep
    When -> @fn.findInterpolation @cb
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
    Given -> @fn = @subject.create {}

    context 'error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ 'read', 'replace', 'write' ], sinon.match.func).callsArgWith 1, 'error'
      When -> @fn.replaceInterpolation @next,
        findInterpolation: ['./foo', './bar']
      Then -> expect(@next).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @async.waterfall = sinon.stub()
      Given -> @async.waterfall.withArgs([ 'read', 'replace', 'write' ], sinon.match.func).callsArgWith 1, null
      When -> @fn.replaceInterpolation @next,
        findInterpolation: ['./foo', './bar']
      Then -> expect(@next).to.have.been.calledWith()

  describe '.read', ->
    Given -> @cb = sinon.spy()
    Given -> @fs.readFile = sinon.stub()
    Given -> @fn = @subject.replace './foo', {}
    context 'error', ->
      Given -> @fs.readFile.withArgs('./foo', 'utf8', sinon.match.func).callsArgWith 2, 'error', null
      When -> @fn.read @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'no error', ->
      Given -> @fs.readFile.withArgs('./foo', 'utf8', sinon.match.func).callsArgWith 2, null, 'data'
      When -> @fn.read @cb
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
    Given -> @fn = @subject.replace './foo', @options
    And -> @fn.replace 'some <%= data %> we found in <%= repoName %>', @cb
    Then -> expect(@cb).to.have.been.calledWith null, 'some words we found in xanadu'

  describe '.write', ->
    Given -> @next = sinon.spy()
    Given -> @fs.writeFile = sinon.stub()
    Given -> @fn = @subject.replace './foo', {}
    context 'no error', ->
      Given -> @fs.writeFile.withArgs('./foo', 'a better monkey', sinon.match.func).callsArgWith 2, null
      When -> @fn.write 'a better monkey', @next
      Then -> expect(@next).to.have.been.calledWith null

    context 'error', ->
      Given -> @fs.writeFile.withArgs('./foo', 'a better monkey', sinon.match.func).callsArgWith 2, 'error'
      When -> @fn.write 'a better monkey', @next
      Then -> expect(@next).to.have.been.calledWith 'error'

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
      , sinon.match.func).callsArgWith 2, 'error', null, null
      Given -> @options =
        user: 'theBigFoo'
        repoName: 'repo'
        description: 'a repo'
        private: true
        wiki: true
        issues: true
      Given -> @fn = @subject.create @options
      When -> @fn.createRepo @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

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
        , sinon.match.func).callsArgWith 2, null, 'res',
          html_url: 'http://github.com/foo/bar'
          some:
            fake: 'stuff'
          that:
            github: 'returns'
        Given -> @options =
          user: 'theBigFoo'
          repoName: 'repo'
          description: 'a repo'
          private: true
          wiki: true
          issues: true
        Given -> @fn = @subject.create @options
        When -> @fn.createRepo @cb
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
        , sinon.match.func).callsArgWith 2, null, 'res',
          html_url: 'http://github.com/pizza/delivery'
          some:
            fake: 'stuff'
          that:
            github: 'returns'
        Given -> @options =
          user: 'theBigFoo'
          repoName: 'repo'
          description: 'a repo'
          private: false
          wiki: false
          issues: false
        Given -> @fn = @subject.create @options
        When -> @fn.createRepo @cb
        Then -> expect(@cb).to.have.been.called
        And -> expect(@options.repo).to.deeply.equal
          html_url: 'http://github.com/pizza/delivery'
          some:
            fake: 'stuff'
          that:
            github: 'returns'

  describe '.createRemote', ->
    Given -> @cb = sinon.spy()
    Given -> @cp.exec = sinon.stub()
    Given -> @options =
      cwd: './bobloblaw'
      repo:
        clone_url: 'git@github.com:tandrewnichols/bobloblaw'
    Given -> @fn = @subject.create @options

    context 'error', ->
      Given -> @cp.exec.withArgs('git remote add origin git@github.com:tandrewnichols/bobloblaw',
        stdio: 'inherit'
        cwd: './bobloblaw'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      When -> @fn.createRemote @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'
      
    context 'stderr', ->
      Given -> @cp.exec.withArgs('git remote add origin git@github.com:tandrewnichols/bobloblaw',
        stdio: 'inherit'
        cwd: './bobloblaw'
      , sinon.match.func).callsArgWith 2, null, null, 'stderr'
      When -> @fn.createRemote @cb
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

    context 'success', ->
      Given -> @cp.exec.withArgs('git remote add origin git@github.com:tandrewnichols/bobloblaw',
        stdio: 'inherit'
        cwd: './bobloblaw'
      , sinon.match.func).callsArgWith 2, null, 'data', null
      When -> @fn.createRemote @cb
      Then -> expect(@cb).to.have.been.called

  describe '.add', ->
    Given -> @cb = sinon.spy()
    Given -> @cp.exec = sinon.stub()
    Given -> @options =
      cwd: './moosen'
    Given -> @fn = @subject.create @options

    context 'no error', ->
      Given -> @cp.exec.withArgs('git add .',
        stdio: 'inherit'
        cwd: './moosen'
      , sinon.match.func).callsArgWith 2, null, 'data', null
      When -> @fn.add @cb
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      Given -> @cp.exec.withArgs('git add .',
        stdio: 'inherit'
        cwd: './moosen'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      When -> @fn.add @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'stderr', ->
      Given -> @cp.exec.withArgs('git add .',
        stdio: 'inherit'
        cwd: './moosen'
      , sinon.match.func).callsArgWith 2, null, null, 'stderr'
      When -> @fn.add @cb
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

  describe '.commit', ->
    Given -> @options =
      cwd: './fuzzy-lovehandles'
      template: 'foo/bar'
    Given -> @cb = sinon.spy()
    Given -> @cp.exec = sinon.stub()
    Given -> @fn = @subject.create @options

    context 'no error', ->
      Given -> @cp.exec.withArgs('git commit -m "Initial commit using tinder template foo/bar"',
        stdio: 'inherit'
        cwd: './fuzzy-lovehandles'
      , sinon.match.func).callsArgWith 2, null, 'data', null
      When -> @fn.commit @cb
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      Given -> @cp.exec.withArgs('git commit -m "Initial commit using tinder template foo/bar"',
        stdio: 'inherit'
        cwd: './fuzzy-lovehandles'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      When -> @fn.commit @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'stderr', ->
      Given -> @cp.exec.withArgs('git commit -m "Initial commit using tinder template foo/bar"',
        stdio: 'inherit'
        cwd: './fuzzy-lovehandles'
      , sinon.match.func).callsArgWith 2, null, null, 'stderr'
      When -> @fn.commit @cb
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

  describe '.push', ->
    Given -> @cb = sinon.spy()
    Given -> @cp.exec = sinon.stub()
    Given -> @options =
      cwd: './michael-jackson-impersonater'
    Given -> @fn = @subject.create @options

    context 'no error', ->
      Given -> @cp.exec.withArgs('git push origin master',
        stdio: 'inherit'
        cwd: './michael-jackson-impersonater'
      , sinon.match.func).callsArgWith 2, null, 'data', null
      When -> @fn.push @cb
      Then -> expect(@cb).to.have.been.called

    context 'error', ->
      Given -> @cp.exec.withArgs('git push origin master',
        stdio: 'inherit'
        cwd: './michael-jackson-impersonater'
      , sinon.match.func).callsArgWith 2, 'error', null, null
      When -> @fn.push @cb
      Then -> expect(@cb).to.have.been.calledWith 'error'

    context 'stderr', ->
      Given -> @cp.exec.withArgs('git push origin master',
        stdio: 'inherit'
        cwd: './michael-jackson-impersonater'
      , sinon.match.func).callsArgWith 2, null, null, 'stderr'
      When -> @fn.push @cb
      Then -> expect(@cb).to.have.been.calledWith 'stderr'

  describe '.chdir', ->
    afterEach -> process.chdir.restore()
    Given -> sinon.stub process, 'chdir'
    Given -> @cb = sinon.spy()
    Given -> @options =
      repoName: 'inebriated-barber'
    Given -> @fn = @subject.create @options
    When -> @fn.chdir @cb
    Then -> expect(process.chdir).to.have.been.calledWith 'inebriated-barber'
