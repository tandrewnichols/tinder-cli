var request = require('request'),
    async = require('async'),
    cp = require('child_process'),
    fs = require('fs'),
    _ = require('underscore');

exports.getGithubUrl = function(options) {
  return function(next) {
    if (/^git@github\.com/.test(options.template)) {
      next(null, options.template);
    } else if (~options.template.indexOf('/')) {
      next(null, 'git@github.com:' + options.template + '.git');
    } else {
      request.get('https://registry.npmjs.org/' + options.template + '/latest', function(err, res, body) {
        if (err) next(err, null);
        else if (!body) next('https://registry.npmjs.org timed out processing the request', null);
        else next(null, body.homepage.replace('https://github.com/', 'git@github.com:') + '.git');
      });
    }
  };
};

exports.clone = function(options) {
  return function(cloneUrl, next) {
    cp.exec('git clone ' + cloneUrl + ' ' + options.repoName, function(err, stdout, stderr) {
      if (err) next(err);
      else if (stderr) next(stderr);
      else {
        console.log(('Created ' + options.repoName).green);
        process.chdir(options.repoName);
        next(null);
      }
    });
  };
};

exports.findInterpolation = function(options) {
  return function(next) {
    var files = '';
    var pattern = [options.interpolate, options.evaluate, options.escape].join('|');
    var grep = cp.spawn('grep', ['-rlP', pattern, '.']);
    grep.stdout.on('data', function(data) {
      files += data.toString();
    });
    grep.on('close', function() {
      next(null, files.split('\n'));
    });
  };
};

exports.replaceInterpolation = function(options) {
  return function(files, next) {
    async.each(files, function(file, cb) {
      async.waterfall([
        exports.read(file),
        exports.replace(options),
        exports.write(file)
      ], function (err) {
        if (err) cb(err);
        else cb();
      });
    }, function(err) {
      if (err) next(err);
      else next();
    });
  };
};

exports.read = function(file) {
  return function(next) {
    fs.readFile(file, function(err, data) {
      if (err) next(err);
      else next(null, data);
    });
  };
};

exports.replace = function(options) {
  return function(data, next) {
    _.templateSettings = {
      interpolate: new RegExp(options.interpolate, 'g'),
      evaluate: new RegExp(options.evaluate, 'g'),
      escape: new RegExp(options.escape, 'g')
    };
    next(null, _.template(data, options.vars));
  };
};

exports.write = function(file) {
  return function(data, next) {
    fs.writeFile(file, data, next);
  };
};

exports.createRepo = function(options) {

};
