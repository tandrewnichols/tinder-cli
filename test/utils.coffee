xdescribe 'utils', ->
  Given -> @fs = {}
  Given -> @fakeConfig =
    '@noCallThru': true
  Given -> @tilde = sinon.stub()
  Given -> @subject = sandbox '../lib/utils',
    fs: @fs
    '/foo/bar': @fakeConfig
    'tilde-expansion': @tilde

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
