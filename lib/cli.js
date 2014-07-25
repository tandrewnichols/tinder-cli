var cp = require('child_process'),
    extend = require('config-extend'),
    async = require('async'),
    git = require('./git'),
    bash = require('./bash'),
    interpolation = require('./interpolation');

var self = exports;

exports.cleanup = function(msg, options) {
  console.log(msg);
  if (options.clean) {
    console.log('Cleaning up...');
    async.parallel([
      bash.rm.bind(bash, options.repoName),
      bash.rm.bind(bash, options.tempDir)
    ], function(err) {
      if (err) self.exit(1, err);
      else self.exit(1, 'Removed ' + options.repoName + ' and temp dir');
    });
  } else {
    self.exit(1, ('Not removing ' + options.repoName + ' and temp dir').red);
  }
};

exports.exit =  function(code, msg) {
  if (typeof code === 'number') {
    console.log(msg);
    process.exit(code);
  } else if (typeof code === 'undefined') {
    process.exit();
  } else {
    console.log(code);
    process.exit();
  }
};

exports.getEnvConfig = function(options) {
  var env = process.env.NODE_ENV || 'production';
  options.config = require('../config/' + env);
};

exports.create = function(name, template, description, options) {
  exports.getEnvConfig(options);
  if (options.user && ~options.user.indexOf(':')) {
    var parts = options.user.split(':');
    options.user = parts[0];
    options.pass = parts[1];
  }
  options.vars = options.vars || {};
  extend(options, options.vars);
  options.repoName = name;
  options.cwd = './' + name;
  options.template = template ? template : options.template;
  options.description = description ? description : options.description;
  async.series([
    git.getGithubUrl.bind(git, options),
    git.clone.bind(git, options),
    bash.copy.bind(bash, options),
    interpolation.find.bind(interpolation, options),
    interpolation.iterate.bind(interpolation, options),
    git.createRepo.bind(git, options),
    git.init.bind(git, options),
    git.createRemote.bind(git, options),
    git.add.bind(git, options),
    git.commit.bind(git, options),
    git.push.bind(git, options),
    bash.cleanup.bind(bash, options)
  ], function(err){
    if (err) self.cleanup(err, options);  
    else self.exit();
  });
};

//exports.register = function(options) {
  //async.auto({
    //config: utils.fetch.bind(utils, options),
    //update: ['config', utils.update.bind(utils, options)]
  //}, function(err) {
    //if (err) self.exit(1, err);
    //else self.exit();
  //});
//};
