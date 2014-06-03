global.sinon = require 'sinon'
global.expect = require('indeed').expect
indeed = require('indeed').indeed
indeed.mixin
  functions: (conditions...) ->
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
