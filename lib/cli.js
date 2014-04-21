var fs = require('fs'),
    cp = require('child_process'),
    utils = require('./utils');

var self = exports;

exports.cleanup = function(msg, options) {
  console.log(msg);
  if (options.clean) {
    console.log("Cleaning up ./" + options.repoName);
    if (process.cwd().split('/').pop() === options.repoName) {
      process.chdir('..');
    }
    cp.exec('rm -rf ' + options.repoName, function(err, stdout, stderr) {
      process.exit(1);
    });
  } else {
    console.log(("Not removing ./" + options.repoName).red);
    process.exit(1);
  }
};

exports.exit = function(code, msg) {
  if (msg) console.log(msg);
  if (code) process.exit(code);
  else process.exit();
};

exports.create = function(name, template, options) {
  if (!/^http/.test(template)) {
    template = utils.getGithubUrl(template);
  }
};
