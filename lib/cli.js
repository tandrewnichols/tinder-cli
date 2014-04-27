var fs = require('fs'),
    cp = require('child_process'),
    utils = require('./utils'),
    $ = require('varity');

var self = exports;

exports.cleanup = function(msg, options) {
  console.log(msg);
  if (options.clean) {
    console.log("Cleaning up...");
    if (process.cwd().split('/').pop() === options.repoName) {
      process.chdir('..');
    }
    cp.exec('rm -rf ' + options.repoName, function(err, stdout, stderr) {
      self.exit(1, "Removed " + options.repoName);
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
  utils.getGithubUrl(template, function(err, cloneUrl){
    if (err) self.cleanUp(err, options);
    options.cloneUrl = cloneUrl;
    utils.clone(options, function(err) {
      
    });
  });
};
