var cp = require('child_process'),
    _ = require('underscore');

exports.copy = function(options, next, data) {
  var copy = cp.spawn('cp', ['-Ri', options.tempDir + '/template', options.repoName], { stdio: 'inherit' });
  copy.on('close', function(code) {
    if (code) next('cp -Ri ' + options.tempDir + '/template ' + options.repoName + ' returned code ' + code);
    else next();
  });
};

exports.cleanup = function(options, next) {
  var rm = cp.spawn('rm', ['-rf', options.tempDir], { stdio: 'inherit' });
  rm.on('close', function(code) {
    if (code) next('Unable to delete temporary directory ' + options.tempDir);
    else next();
  });
};

