r = require('path').resolve

describe 'utils', ->
  Given -> @foo =
    '@noCallThru': true
    dependencies: ['x', 'y', 'z']
    devDependencies: [1, 2, 3]
    foo:
      baz: 'quux'
  Given -> @path = {}
  Given -> @subject = sandbox r('lib/utils'),
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
