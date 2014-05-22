var request = require('request'),
    async = require('async'),
    cp = require('child_process'),
    fs = require('fs'),
    _ = require('underscore'),
    extend = require('config-extend');

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
        console.log('Cloned ' + cloneUrl);
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
      else {
        console.log('Replaced all interpolation');
        next();
      }
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
  return function(next) {
    var json = {
      name: options.repoName,
      description: options.description || '',
      private: !!options.private,
      has_wiki: !!options.wiki,
      has_issues: !!options.issues
    };
    request.post('https://api.github.com/user/repos', { json: json, auth: { user: options.user } }, function(err, res, body) {
      if (err) next(err);
      else {
        extend(options, { repo: body });
        console.log('Created new repo at ' + options.repo.html_url);
        next();
      };
    });
  };
};

exports.createRemote = function(options) {
  return function(next) {
    cp.exec('git remote add origin ' + options.repo.clone_url, function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        console.log('Created remote', 'origin'.blue, 'at', options.repo.clone_url.cyan);
        next();
      }
    });
  };
};

exports.add = function(options) {

};

exports.commit = function(options) {
  return function(next) {
    cp.exec('git add .', function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        cp.exec('git commit -m "Initial commit using tinder template ' + options.template + '"', function(err, stdout, stderr) {
          if (err || stderr) next(err || stderr);
          else {
            next();
          }
        });
      }
    });
  };
};
