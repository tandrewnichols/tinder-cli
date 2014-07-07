var cp = require('child_process'),
    _ = require('underscore');

exports.copy = function(options, next, data) {
  var dir = options.clonedDir = _(data.getGithubUrl.split('/')).last().split('.')[0];
  var copy = cp.spawn('cp', ['-Ri', dir + '/template', options.repoName], { stdio: 'inherit' });
  copy.on('close', function(code) {
    if (code) next('cp -Ri ' + dir + '/template ' + options.repoName + ' returned code ' + code);
    else next();
  });
};

exports.cleanup = function(options, next) {
  var rm = cp.spawn('rm', ['-rf', options.clonedDir], { stdio: 'inherit' });
  rm.on('close', function(code) {
    if (code) next('Unable to delete temporary directory ./' + options.clonedDir);
    else next();
  });
};

