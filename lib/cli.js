var cp = require('child_process'),
    $ = require('varity'),
    extend = require('config-extend'),
    async = require('async'),
    git = require('./git'),
    bash = require('./bash'),
    interpolation = require('./interpolation');

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
  async.auto({
    getGithubUrl: utils.getGithubUrl.bind(utils, options),
    clone: ['getGithubUrl', utils.clone.bind(utils, options)],
    copy: ['clone', utils.copy.bind(utils, options)],
    findInterpolation: ['copy', utils.findInterpolation.bind(utils, options)],
    replaceInterpolation: ['findInterpolation', utils.replaceInterpolation.bind(utils, options)],
    createRepo: utils.createRepo.bind(utils, options),
    createRemote: ['copy', 'createRepo', utils.createRemote.bind(utils, options)],
    add: ['replaceInterpolation', 'createRemote', utils.add.bind(utils, options)],
    commit: ['add', utils.commit.bind(utils, options)],
    push: ['commit', utils.push.bind(utils, options)],
    cleanup: ['copy', utils.cleanup.bind(utils, options)]
  }, function(err){
    if (err) self.cleanup(err, options);  
    else self.exit();
  });
};

exports.register = function(options) {
  async.auto({
    config: utils.fetch.bind(utils, options),
    update: ['config', utils.update.bind(utils, options)]
  }, function(err) {
    if (err) self.exit(1, err);
    else self.exit();
  });
};
