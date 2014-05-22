var cp = require('child_process'),
    utils = require('./utils'),
    $ = require('varity'),
    async = require('async');

var self = exports;

exports.cleanup = function(msg, options) {
  console.log(msg);
  if (options.clean) {
    console.log("Cleaning up...");
    if (process.cwd().split('/').pop() === options.repoName) {
      process.chdir('..');
    }
    cp.exec('rm -rf ' + options.repoName, function(err, stdout, stderr) {
      if (err) self.exit(1, err);
      else if (stderr) self.exit(1, stderr);
      else self.exit(1, "Removed " + options.repoName);
    });
  } else {
    self.exit(1, ("Not removing ./" + options.repoName).red);
  }
};

exports.exit = $('1s', function(code, msg) {
  if (msg) console.log(msg);
  if (code) process.exit(code);
  else process.exit();
});

exports.create = function(name, template, options) {
  options.repoName = name;
  options.template = template;
  options.vars = options.vars || {};
  options.vars.repoName = name;
  async.auto({
    getGithubUrl: utils.getGithubUrl(options),
    clone: ['getGithubUrl', utils.clone(options)],
    findInterpolation: ['clone', utils.findInterpolation(options)],
    replaceInterpolation: ['findInterpolation', utils.replaceInterpolation(options)],
    createRepo: utils.createRepo(options),
    createRemote: ['createRepo', utils.createRemote(options)],
    commit: ['replaceInterpolation', 'createRemote', utils.commit(options)]
  }, function(err){
    if (err) self.cleanup(err, options);  
    self.exit();
  });
};
