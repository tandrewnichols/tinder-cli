var cp = require('child_process'),
    _ = require('underscore');

exports.copy = function(options, next) {
  var copy = cp.spawn('cp', ['-Ri', options.tempDir + '/template', options.repoName], { stdio: 'inherit' });
  copy.on('close', function(code) {
    if (code) next('cp -Ri ' + options.tempDir + '/template ' + options.repoName + ' returned code ' + code);
    else next();
  });
};

exports.cleanup = function(options, next) {
  exports.rm(options.tempDir, next);
};

exports.rm = function(file, next) {
  var rm = cp.spawn('rm', ['-rf', file], { stdio: 'inherit' });
  rm.on('close', function(code) {
    if (code) next('rm -rf ' + file + ' returned code ' + code);
    else next();
  });
};
