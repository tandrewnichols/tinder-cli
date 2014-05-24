describe 'coercion', ->
  Given -> @subject = require '../lib/coercion'
  describe '.obj', ->
    When -> @res = @subject.obj '{"foo": "bar", "baz": "quux", "nerfherders": [ "lenny", "barry", "ted" ]}'
    Then -> expect(@res).to.deep.equal
      foo: 'bar'
      baz: 'quux'
      nerfherders: [ 'lenny', 'barry', 'ted' ]
