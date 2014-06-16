EventEmitter  = require('events').EventEmitter
colors = require 'colors'
fs = require 'fs'
_ = require 'underscore'

describe 'utils', ->
  Given -> @request = {}
  Given -> @cp = {}
  Given -> @fs = {}
  Given -> @async = {}
  Given -> @fakeConfig =
    '@noCallThru': true
  Given -> @tilde = sinon.stub()
  Given -> @subject = sandbox '../lib/utils',
    request: @request
    child_process: @cp
    fs: @fs
    async: @async
    '/foo/bar': @fakeConfig
    'tilde-expansion': @tilde

  describe '.register', ->
    When -> @obj = @subject.config {}
    Then -> expect(@obj).to.have.functions ['fetch', 'update']

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

  describe '.clone', ->
    Given -> @clone = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['clone', 'git@github.com:foo/bar.git'],
      stdio: 'inherit'
    ).returns @clone

    context 'error', ->
      When -> @subject.clone {}, @cb,
        getGithubUrl: 'git@github.com:foo/bar.git'
      And -> @clone.emit('close', 1)
      Then -> expect(@cb).to.have.been.calledWith 'git clone git@github.com:foo/bar.git returned code 1'

    context 'no error', ->
      When -> @subject.clone {}, @cb,
        getGithubUrl: 'git@github.com:foo/bar.git'
      And -> @clone.emit('close', 0)
      Then -> expect(@cb).to.have.been.called

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
      Then -> expect(@cb).to.have.been.calledWith 'https://api.github.com/user/repos responded with status code 418', null

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

  describe '.createRemote', ->
    Given -> @remote = new EventEmitter()
    Given -> @cb = sinon.spy()
    Given -> @cp.spawn = sinon.stub()
    Given -> @cp.spawn.withArgs('git', ['remote', 'set-url', 'origin', 'git@github.com:tandrewnichols/bobloblaw'],
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
      Then -> expect(@cb).to.have.been.calledWith 'git remote set-url origin git@github.com:tandrewnichols/bobloblaw returned code 1'
      
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

  describe '.fetch', ->
    Given -> @cb = sinon.stub()
    Given -> @fs.exists = sinon.stub()
    Given -> @fs.exists.withArgs('/foo/bar', sinon.match.func).callsArgWith 1, true

    context 'with config specified', ->
      Given -> @options =
        config: '/foo/bar'
      Given -> @fakeConfig.foo = 'data'
      When -> @fn = @subject.config @options
      And -> @fn.fetch @cb
      Then -> expect(@cb).to.have.been.calledWith null,
        '@noCallThru': true
        foo: 'data'

    context 'with no config specified', ->
      Given -> @tilde.withArgs('~/.tinder.json', sinon.match.func).callsArgWith 1, '/foo/bar'
      Given -> @fakeConfig.foo = 'data'
      When -> @fn = @subject.config {}
      And -> @fn.fetch @cb
      Then -> expect(@cb).to.have.been.calledWith null,
        '@noCallThru': true
        foo: 'data'

    context 'config does not exist', ->
      Given -> @options =
        config: '/bar/foo'
      Given -> @fs.exists.withArgs('/bar/foo', sinon.match.func).callsArgWith 1, false
      When -> @fn = @subject.config @options
      And -> @fn.fetch @cb
      Then -> expect(@cb).to.have.been.calledWith null, {}

  describe.skip '.mapRemotes', ->
    Given -> @options =
      template: [
        key: 'bar'
        name: 'foo/bar'
      ,
        key: 'quux'
        name: 'baz/quux'
      ]
    Given -> @cb = sinon.spy()
    #When -> 

  describe '.update', ->
    Given -> @cb = sinon.stub()
    Given -> @data =
      config: {}

    context 'with templates and vars', ->
      Given -> @options =
        user: 'goldilocks'
        template: [
          key: 'bar'
          name: 'foo/bar'
          remote: 'git@github.com:foo/bar.git'
        ,
          key: 'quux'
          name: 'baz/quux'
          remote: 'git@github.com:baz/quux.git'
        ]
        vars:
          type: []
        interpolate: 'interpolate'
        evaluate: 'evaluate'
        escape: 'escape'
      When -> @fn = @subject.config @options
      And -> @fn.update @cb, @data
      Then -> expect(@data.config).to.deep.equal
        user: 'goldilocks'
        templates:
          bar:
            name: 'foo/bar'
            remote: 'git@github.com:foo/bar.git'
            vars:
              type: []
          quux:
            name: 'baz/quux'
            remote: 'git@github.com:baz/quux.git'
            vars:
              type: []
        interpolate: 'interpolate'
        evaluate: 'evaluate'
        escape: 'escape'

    context 'with templates but no vars', ->
      Given -> @options =
        user: 'goldilocks'
        template: [
          key: 'bar'
          name: 'foo/bar'
          remote: 'git@github.com:foo/bar.git'
        ,
          key: 'quux'
          name: 'baz/quux'
          remote: 'git@github.com:baz/quux.git'
        ]
      When -> @fn = @subject.config @options
      And -> @fn.update @cb, @data
      Then -> expect(@data.config).to.deep.equal
        user: 'goldilocks'
        templates:
          bar:
            name: 'foo/bar'
            remote: 'git@github.com:foo/bar.git'
            vars: {}
          quux:
            name: 'baz/quux'
            remote: 'git@github.com:baz/quux.git'
            vars: {}

    context 'with no templates but vars', ->
      Given -> @options =
        template: []
        vars:
          contributors: []
          types: {}
      When -> @fn = @subject.config @options
      And -> @fn.update @cb, @data
      Then -> expect(@data.config).to.deep.equal
        vars:
          contributors: []
          types: {}
