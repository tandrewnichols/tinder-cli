fs = require 'fs'
path = require 'path'
WordGenerator = require 'wordgenerator'
spawn = require('child_process').spawn
async = require 'async'
_ = require 'underscore'
EventEmitter = require('events').EventEmitter

describe 'acceptance', ->
  Given (done) -> new WordGenerator { num: 2, separator: '-' }, (err, words) =>
    @repo = words
    done()
  afterEach (done) ->
    rm = spawn "rm", ["-rf", @repo], { cwd: "#{__dirname}/..", stdio: 'inherit' }
    rm.on 'close', ->
      done()
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
  Given -> @clone = new EventEmitter()
  Given -> @copy = new EventEmitter()
  Given -> @remote = new EventEmitter()
  Given -> @add = new EventEmitter()
  Given -> @commit = new EventEmitter()
  Given -> @push = new EventEmitter()
  Given -> @rm = new EventEmitter()
  Given -> sinon.stub @cp, 'spawn', (cmd, args, opts) =>
    switch "#{cmd} #{args.join(' ')}"
      when "git clone git@github.com:tandrewnichols/tinder-template.git" then @clone
      when "cp -Ri tinder-template/template #{@repo}" then @copy
      when "git remote set-url origin git@github.com:tandrewnichols/#{@repo}.git" then @remote
      when "git add ." then @add
      when "git commit -m Initial commit using tinder template tinder-template" then @commit
      when "git push origin master" then @push
      when "rm -rf tinder-template" then @rm
      else spawn.apply(null, arguments)
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
    emitters = [@clone, @copy, @remote, @add, @commit, @push]
    removed = []
    @cli.create @repo, 'tinder-template', undefined, @options
    # Wait for process.exit to be called
    async.whilst (-> !process.exit.getCall(0)),
      ((cb) =>
        setTimeout ( =>
          async.each _(emitters).without(removed), ((e, n) ->
            if e and e.listeners
              removed.push(e)
              e.emit('close', 0)
            n()
          ), cb
        ), 200
      ),done
  And -> @clone.emit('close', 0)
  And -> @copy.emit('close', 0)
  And -> @remote.emit('close', 0)
  And -> @add.emit('close', 0)
  And -> @commit.emit('close', 0)
  And -> @push.emit('close', 0)
  And -> @blah = require "../#{@repo}/blah"
  Then ->
    expect(@blah.repoName).to.equal "This repo is called #{@repo}"
    expect(@blah.foo).to.equal 'It was created with var "foo" = "bar"'
    expect(@blah.baz).to.equal 'q|u|u|x'
