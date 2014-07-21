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
            else self.exit(1, "Removed " + options.repoName + " and " + options.clonedDir);
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

exports.create = function(name, template, description, options) {
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
