var cp = require('child_process'),
    request = require('request'),
    extend = require('config-extend'),
    rand = require('randomstring');

exports.getGithubUrl = function(options, next) {
  var msg = null;
  if (!options.template) msg = 'Unable to construct a github url. No template provided.';
  else if (/^git@github\.com/.test(options.template)) options.githubUrl = options.template;
  else if (~options.template.indexOf('/')) options.githubUrl = 'git@github.com:' + options.template + '.git';
  else if (options.template && options.user) options.githubUrl = 'git@github.com:' + options.user + '/' + options.template + '.git';
  else msg = 'Unable to construct a github url. The template was not in a known form and no github username was provided.';
  next(msg);
};

exports.clone = function(options, next) {
  var randStr = rand.generate();
  options.tempDir = './' + randStr;
  var clone = cp.spawn('git', ['clone', options.githubUrl, randStr], { stdio: 'inherit' });
  clone.on('close', function(code) {
    if (code) next('git clone ' + options.githubUrl + ' returned code ' + code);
    else {
      console.log('Cloned ' + options.githubUrl);
      next();
    }
  });
};

exports.createRepo = function(options, next) {
  var opts = {
    json: {
      name: options.repoName,
      description: options.description || '',
      private: !!options.private,
      has_wiki: !!options.wiki,
      has_issues: !!options.issues
    },
    auth: {
      user: options.user,
      pass: options.pass
    },
    headers: {
      'User-Agent': options.repoName
    }
  };
  request.post('https://api.github.com/user/repos', opts, function(err, res, body) {
    if (err) next(err);
    else if (res.statusCode > 299) next('https://api.github.com/user/repos responded with status code ' + res.statusCode);
    else {
      extend(options, { repo: body });
      console.log('Created new repo at ' + options.repo.html_url.green);
      next();
    }
  });
};

exports.init = function(options, next) {
  var init = cp.spawn('git', ['init'], { stdio: 'inherit', cwd: options.cwd });
  init.on('close', function(code) {
    if (code) next('git init returned code ' + code);
    else next();
  });
};

exports.createRemote = function(options, next) {
  var remote = cp.spawn('git', ['remote', 'add', 'origin', options.repo.clone_url], { stdio: 'inherit', cwd: options.cwd });
  remote.on('close', function(code) {
    if (code) next('git remote add origin ' + options.repo.clone_url + ' returned code ' + code);
    else {
      console.log('Set remote', 'origin'.green, 'to', options.repo.clone_url.green);
      next();
    }
  });
};
 
exports.add = function(options, next) {
  var add = cp.spawn('git', ['add', '.'], { stdio: 'inherit', cwd: options.cwd });
  add.on('close', function(code){
    if (code) next('git add . returned code ' + code);
    else next();
  });
};

exports.commit = function(options, next) {
  var commit = cp.spawn('git', ['commit', '-m', 'Initial commit using tinder template ' + options.template], { stdio: 'inherit', cwd: options.cwd });
  commit.on('close', function(code){
    if (code) next('git commit -m "Initial commit using tinder template ' + options.template + '" returned code ' + code);
    else next();
  });
};

exports.push = function(options, next) {
  var push = cp.spawn('git', ['push', 'origin', 'master'], { stdio: 'inherit', cwd: options.cwd });
  push.on('close', function(code) {
    if (code) next('git push origin master returned code ' + code);
    else next();
  });
};
