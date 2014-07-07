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
    getGithubUrl: git.getGithubUrl.bind(git, options),
    clone: ['getGithubUrl', git.clone.bind(git, options)],
    copy: ['clone', bash.copy.bind(bash, options)],
    findInterpolation: ['copy', interpolation.find.bind(interpolation, options)],
    replaceInterpolation: ['findInterpolation', interpolation.iterate.bind(interpolation, options)],
    createRepo: git.createRepo.bind(git, options),
    createRemote: ['copy', 'createRepo', git.createRemote.bind(git, options)],
    add: ['replaceInterpolation', 'createRemote', git.add.bind(git, options)],
    commit: ['add', git.commit.bind(git, options)],
    push: ['commit', git.push.bind(git, options)],
    cleanup: ['copy', bash.cleanup.bind(bash, options)]
  }, function(err){
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
