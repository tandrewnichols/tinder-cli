var request = require('request'),
    cp = require('child_process');

exports.getGithubUrl = function(template, cb) {
  if (/^git@github\.com/.test(template)) {
    cb(null, template);
  } else if (~template.indexOf('/')) {
    cb(null, 'git@github.com:' + template + '.git');
  } else {
    request.get('https://registry.npmjs.org/' + template + '/latest', function(err, res, body) {
      if (err) cb(err, null);
      else if (!body) cb('https://registry.npmjs.org timed out processing the request', null);
      else {
        cb(null, body.homepage.replace('https://github.com/', 'git@github.com:') + '.git');
      }
    });
  }
};

exports.clone = function(options, cb) {
  cp.exec('git clone ' + options.cloneUrl + ' ' + options.repoName, function(err, stdout, stderr) {
    if (err) cb(err);
    else if (stderr) cb(stderr);
    else {
      console.log('Created ' + options.repoName);
      process.chdir(options.repoName);
      cb();
    }
  });
};

exports.findInterpolationFiles = function(options, cb) {

};
