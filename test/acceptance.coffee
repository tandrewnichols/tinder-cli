fs = require 'fs'
WordGenerator = require 'wordgenerator'
cp = require 'child_process'
async = require 'async'
_ = require 'underscore'

describe 'acceptance', ->
  Given (done) -> new WordGenerator { num: 2, separator: '-' }, (err, words) =>
    @repo = words
    done()
  afterEach (done) ->
    rm = cp.spawn "rm", ["-rf", @repo], { cwd: "#{__dirname}/..", stdio: 'inherit' }
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
  , sinon.match.func).callsArgWith 2, null,
    statusCode: 200
  ,
    html_url: "https://github.com/tandrewnichols/#{@repo}"
    clone_url: "git@github.com:tandrewnichols/#{@repo}.git"
  Given -> @cp.exec = sinon.stub()
  Given -> @cp.exec.withArgs("git clone git@github.com:tandrewnichols/tinder-template.git #{@repo}",
    stdio: 'inherit'
    cwd: "./#{@repo}"
  , sinon.match.func).callsArgWith 2, null, {}, null
  Given -> @cp.exec.withArgs("git remote add origin git@github.com:tandrewnichols/#{@repo}.git",
    stdio: 'inherit'
    cwd: "./#{@repo}"
  , sinon.match.func).callsArgWith 2, null, {}, null
  Given -> @cp.exec.withArgs("git add .",
    stdio: 'inherit'
    cwd: "./#{@repo}"
  , sinon.match.func).callsArgWith 2, null, {}, null
  Given -> @cp.exec.withArgs('git commit -m "Initial commit using tinder template tinder-template"',
    stdio: 'inherit'
    cwd: "./#{@repo}"
  , sinon.match.func).callsArgWith 2, null, {}, null
  Given -> @cp.exec.withArgs('git push origin master',
    stdio: 'inherit'
    cwd: "./#{@repo}"
  , sinon.match.func).callsArgWith 2, null, {}, null
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
    @cli.create @repo, 'tinder-template', @options
    async.whilst (-> !process.exit.getCall(0)),
      ((cb) -> setTimeout(cb, 200)),
      done
  And -> @blah = require "../#{@repo}/blah"
  Then ->
    expect(@blah.repoName).to.equal "This repo is called #{@repo}"
    expect(@blah.foo).to.equal 'It was created with var "foo" = "bar"'
    expect(@blah.baz).to.equal 'q|u|u|x'
