r = require('path').resolve

describe 'utils', ->
  Given -> @foo =
    '@noCallThru': true
    dependencies: ['x', 'y', 'z']
    devDependencies: [1, 2, 3]
    foo:
      baz: 'quux'
  Given -> @path = {}
  Given -> @fs = {}
  Given -> @git = {}
  Given -> @child_process = {}
  Given -> @subject = sandbox r('lib/utils'),
    child_process: @child_process
    'git-wrapper2': @git
    fs: @fs
    path: @path
    './foo': @foo

  describe '.extendOptionsFromFile', ->
    Given -> @path.resolve = sinon.stub().returnsArg(0)
    context 'extend', ->
      Given -> @options =
        optsFile: './foo'
        extend: true
        foo:
          bar: 'bar'
          baz: 'baz'
        dependencies: ['a', 'b', 'c']
        devDependencies: ['d', 'e', 'f']
      When -> @subject.extendOptionsFromFile @options
      Then -> expect(@options).to.deep.equal
        optsFile: './foo'
        extend: true
        foo:
          bar: 'bar'
          baz: 'quux'
        dependencies: ['a', 'b', 'c', 'x', 'y', 'z']
        devDependencies: ['d', 'e', 'f', 1, 2, 3]
        '@noCallThru': true

    context 'no extend', ->
      Given -> @options =
        optsFile: './foo'
        extend: false
        foo:
          bar: 'bar'
          baz: 'baz'
        dependencies: ['a', 'b', 'c']
        devDependencies: ['d', 'e', 'f']
      When -> @subject.extendOptionsFromFile @options
      Then -> expect(@options).to.deep.equal
        optsFile: './foo'
        extend: false
        foo:
          bar: 'bar'
          baz: 'quux'
        dependencies: ['x', 'y', 'z']
        devDependencies: [1, 2, 3]
        '@noCallThru': true

    context 'path does not exist', ->
      Given -> @options =
        optsFile: './bar'
        extend: true
        foo:
          bar: 'bar'
          baz: 'baz'
        dependencies: ['a', 'b', 'c']
        devDependencies: ['d', 'e', 'f']
      When -> @subject.extendOptionsFromFile @options
      Then -> expect(@options).to.deep.equal
        optsFile: './bar'
        extend: true
        foo:
          bar: 'bar'
          baz: 'baz'
        dependencies: ['a', 'b', 'c']
        devDependencies: ['d', 'e', 'f']

  describe '.mkdir', ->
    Given -> @fs.mkdir = sinon.stub().withArgs('./whale-bait', sinon.match.func).callsArg(1)
    Given -> @done = sinon.spy()
    When -> @subject.mkdir('whale-bait', @done)
    Then -> expect(@done).to.have.been.called

  describe '.gitUrls', ->
    Given -> @options =
      githubAccount: 'ahab'
      name: 'whale-bait'
    When -> @subject.gitUrls @options
    Then -> expect(@options).to.deep.equal
      githubAccount: 'ahab'
      name: 'whale-bait'
      cloneUrl: 'git@github.com:ahab/whale-bait.git'
      gitUrl: 'git://github.com/ahab/whale-bait'
      githubUrl: 'https://github.com/ahab/whale-bait'

  describe '.initializeGit', ->
    Given -> process.chdir = sinon.spy()
    Given -> @git.exec = sinon.stub()
    Given -> @done = sinon.spy()
    context 'no error', ->
      Given -> @git.exec.withArgs('init', sinon.match.func).callsArgWith(1, null, 'A fake message for testing')
      Given -> @git.exec.withArgs('remote', ['add', 'origin', 'cloneme'], sinon.match.func).callsArg(2)
      When -> @subject.initializeGit 'whale-bait', 'cloneme', @done
      Then -> expect(process.chdir).to.have.been.calledWith './whale-bait'
      And -> expect(@done).to.have.been.called

    context 'error', ->
      Given -> @git.exec.withArgs('init', sinon.match.func).callsArgWith(1, 'A fake error for testing', null)
      When -> @subject.initializeGit 'whale-bait', 'cloneme', @done
      Then -> expect(process.chdir).to.have.been.calledWith './whale-bait'
      And -> expect(@done).to.have.been.calledWith 'A fake error for testing'

  describe '.basePackage', ->
    Given -> @options =
      name: 'cyclic spooning'
      description: 'what goes around comes around'
      author: 'Archibold Keller'
      email: 'akeller@email.com'
      gitUrl: 'git url'
      githubUrl: 'github url'
      package:
        foo: 'bar'
    context 'with main', ->
      Given -> @options.main = './lib/cyclic-spooning'
      When -> @package = @subject.basePackage @options
      Then -> expect(@package).to.deep.equal
        name: 'cyclic spooning'
        description: 'what goes around comes around'
        version: '0.0.1'
        author:
          name: 'Archibold Keller'
          email: 'akeller@email.com'
        repository:
          type: 'git'
          url: 'git url'
        homepage: 'github url'
        bugs:
          url: 'github url/issues'
        licenses: [
          type: 'MIT'
          url: 'github url/blob/master/LICENSE'
        ]
        main: './lib/cyclic-spooning'
        foo: 'bar'

    context 'no main', ->
      When -> @package = @subject.basePackage @options
      Then -> expect(@package).to.deep.equal
        name: 'cyclic spooning'
        description: 'what goes around comes around'
        version: '0.0.1'
        author:
          name: 'Archibold Keller'
          email: 'akeller@email.com'
        repository:
          type: 'git'
          url: 'git url'
        homepage: 'github url'
        bugs:
          url: 'github url/issues'
        licenses: [
          type: 'MIT'
          url: 'github url/blob/master/LICENSE'
        ]
        main: './index'
        foo: 'bar'

    context 'with keywords', ->
      Given -> @options.keywords = ['jigger', 'whatsit']
      When -> @package = @subject.basePackage @options
      Then -> expect(@package).to.deep.equal
        name: 'cyclic spooning'
        description: 'what goes around comes around'
        version: '0.0.1'
        author:
          name: 'Archibold Keller'
          email: 'akeller@email.com'
        repository:
          type: 'git'
          url: 'git url'
        homepage: 'github url'
        bugs:
          url: 'github url/issues'
        licenses: [
          type: 'MIT'
          url: 'github url/blob/master/LICENSE'
        ]
        main: './index'
        foo: 'bar'
        keywords: ['jigger', 'whatsit']

  describe '.writePackage', ->
    Given -> @package =
      leftHanded: true
      profession: 'plumber'
    Given -> @done = sinon.spy()
    Given -> @fs.writeFile = sinon.stub().withArgs('./package.json', JSON.stringify(@package, null, 4), sinon.match.func).callsArg(2)
    When -> @subject.writePackage @package, @done
    Then -> expect(@done).to.have.been.called

  describe '.addDependencies', ->
    Given -> @child_process.spawn = sinon.stub().withArgs('npm install foo bar baz --save')
    context 'regular deps', ->
      Given -> @deps = ['foo', 'bar', 'baz']
      Given -> @done = sinon.spy()
      When -> @subject.addDependencies @deps, @done
      
