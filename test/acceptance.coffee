fs = require 'fs'
WordGenerator = require 'wordgenerator'
spawn = require('child_process').spawn
async = require 'async'
_ = require 'underscore'
EventEmitter = require('events').EventEmitter

describe.skip 'acceptance', ->
  Given (done) -> new WordGenerator { num: 2, separator: '-' }, (err, words) =>
    @repo = words
    done()
  afterEach (done) ->
    rm = spawn "rm", ["-rf", @repo], { cwd: "#{__dirname}/..", stdio: 'inherit' }
    rm.on 'close', ->
      done()
  afterEach -> process.chdir.restore()
  afterEach -> process.exit.restore()
  Given (done) -> fs.mkdir "#{@repo}", done
  Given (done) -> fs.writeFile "#{@repo}/blah.js", """
    module.exports = {
      repoName: 'This repo is called <%= repoName %>',
      foo: 'It was create with var "foo" = "<%= foo %>"',
      baz: '<% print(baz.split(",").join("|")) %>'
    };
    """
  , done
  Given -> @request =
    '@global': true
  Given -> @cp =
    '@global': true
  Given -> @cli = sandbox '../lib/cli',
    request: @request
    child_process: @cp
  Given -> @request.get = sinon.stub()
  Given -> @request.post = sinon.stub()
  Given -> sinon.stub process, 'chdir'
  Given -> sinon.stub process, 'exit'
  Given -> @request.get.withArgs('https://registry.npmjs.org/tinder-template/latest', sinon.match.func).callsArgWith 1, null,
    statusCode: 200
  ,
    homepage: 'https://github.com/tandrewnichols/tinder-template'
  Given -> @request.post.withArgs('https://api.github.com/user/repos',
    json:
      name: @repo
      description: 'A test repository'
      private: false
      has_wiki: true
      has_issues: true
    auth:
      user: 'tandrewnichols'
      pass: 'blahblah'
    headers:
      'User-Agent': @repo
  , sinon.match.func).callsArgWith 2, null,
    statusCode: 200
  ,
    html_url: "https://github.com/tandrewnichols/#{@repo}"
    clone_url: "git@github.com:tandrewnichols/#{@repo}.git"
  Given -> @cp.spawn = sinon.stub()
  #Given -> @cp.spawn.withArgs('grep', ['-rlP', sinon.match.string, "./#{@repo}"])
  Given -> @clone = new EventEmitter()
  Given -> @cp.spawn.withArgs('git', ['clone', 'git@github.com:tandrewnichols/tinder-template.git', @repo],
    stdio: 'inherit'
  ).returns @clone
  Given -> @remote = new EventEmitter()
  Given -> @cp.spawn.withArgs('git', ['remote', 'set-url', 'origin', "git@github.com:tandrewnichols/#{@repo}.git"],
    stdio: 'inherit'
    cwd: "./#{@repo}"
  ).returns @remote
  Given -> @add = new EventEmitter()
  Given -> @cp.spawn.withArgs('git', ['add', '.'],
    stdio: 'inherit'
    cwd: "./#{@repo}"
  ).returns @add
  Given -> @commit = new EventEmitter()
  Given -> @cp.spawn.withArgs('git', ['commit', '-m', 'Initial commit using tinder template tinder-template'],
    stdio: 'inherit'
    cwd: "./#{@repo}"
  ).returns @commit
  Given -> @push = new EventEmitter()
  Given -> @cp.spawn.withArgs('git', ['push', 'origin', 'master'],
    stdio: 'inherit'
    cwd: "./#{@repo}"
  ).returns @push
  Given -> @options =
    user: 'tandrewnichols'
    pass: 'blahblah'
    description: 'A test repository'
    interpolate: _.templateSettings.interpolate.source
    evaluate: _.templateSettings.evaluate.source
    escape: _.templateSettings.escape.source
    private: false
    wiki: true
    issues: true
    vars:
      foo: 'bar'
      baz: 'q,u,u,x'
  When (done) ->
    emitters = [@clone, @remote, @add, @commit, @push]
    @cli.create @repo, 'tinder-template', @options
    async.whilst (-> !process.exit.getCall(0)),
      ((cb) => setTimeout((=>
        for emitter in emitters
          if emitter and emitter.listeners
            emitters = _(emitters).without(emitter)
            emitter.emit('close', 0)
        cb()
      ), 200)),
      done
  And -> @blah = require "../#{@repo}/blah"
  Then ->
    expect(@blah.repoName).to.equal "This repo is called #{@repo}"
    expect(@blah.foo).to.equal 'It was created with var "foo" = "bar"'
    expect(@blah.baz).to.equal 'q|u|u|x'
