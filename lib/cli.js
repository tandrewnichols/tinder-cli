var cp = require('child_process'),
    utils = require('./utils'),
    $ = require('varity'),
    extend = require('config-extend'),
    async = require('async');

var self = exports;

// TODO: Update test
exports.cleanup = function(msg, options) {
  console.log(msg);
  if (options.clean) {
    console.log("Cleaning up...");
    cp.exec('rm -rf ' + options.repoName, function(err, stdout, stderr) {
      if (err) self.exit(1, err);
      else if (stderr) self.exit(1, stderr);
      else {
        if (options.clonedDir) {
          cp.exec('rm -rf ' + options.clonedDir, function(err, stdout, stderr) {
            if (err) self.exit(1, err);
            else if (stderr) self.exit(1, stderr);
            else self.exit(1, "Removed " + options.repoName + " and " + optoins.clonedDir);
          });
        }
        else self.exit(1, "Removed " + options.repoName);
      }
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
  if (~options.user.indexOf(':')) {
    var parts = options.user.split(':');
    options.user = parts[0];
    options.pass = parts[1];
  }
  options.vars = options.vars || {};
  extend(options, options.vars);
  options.repoName = name;
  options.cwd = './' + name;
  options.template = template;
  var repo = utils.create(options);
  async.auto({
    getGithubUrl: repo.getGithubUrl,
    clone: ['getGithubUrl', repo.clone],
    copy: ['clone', repo.copy],
    findInterpolation: ['copy', repo.findInterpolation],
    replaceInterpolation: ['findInterpolation', repo.replaceInterpolation],
    createRepo: repo.createRepo,
    createRemote: ['copy', 'createRepo', repo.createRemote],
    add: ['replaceInterpolation', 'createRemote', repo.add],
    commit: ['add', repo.commit],
    push: ['commit', repo.push],
    cleanup: ['copy', repo.cleanup]
  }, function(err){
    if (err) self.cleanup(err, options);  
    else self.exit();
  });
};

exports.test = function() {
  console.log(arguments);
};
