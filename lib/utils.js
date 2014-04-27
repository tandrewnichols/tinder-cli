var request = require('request');

exports.getGithubUrl = function(template, cb) {
  if (~template.indexOf('/')) {
    cb(null, 'git@github.com:' + template + '.git');
  } else {
    request.get('https://registry.npmjs.org/' + template + '/latest', function(err, res, body) {
      if (err) cb(err, null);
      else if (!body) cb('https://registry.npmjs.org timed out processing the request', null);
      else cb(null, body.homepage.replace('https://github.com/', 'git@github.com:'));
    });
  }
};
