global.sinon = require 'sinon'
global.expect = require('indeed').expect
indeed = require('indeed').indeed
indeed.mixin
  functions: (conditions) ->
    (val) ->
      _(conditions).every (condition) ->
        typeof val[condition] == 'function'

global.sandbox = require 'proxyquire'
_ = require 'underscore'

global.spyObj = (fns...) ->
  _(fns).reduce (obj, fn) ->
    obj[fn] = sinon.stub()
    obj
  , {}

global.stubAll = (obj, stubs) ->
  if _(stubs).isArray()
    for name in stubs
      obj[name] =
        bind: sinon.stub()
      obj[name].bind.returns name
  else if _(stubs).isObject() && stubs.constructor.name == 'Object'
    for k, v of stubs
      obj[k] = sinon.stub()
      obj[k].returns v
