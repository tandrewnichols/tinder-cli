var request = require('request'),
    async = require('async'),
    cp = require('child_process'),
    fs = require('fs'),
    _ = require('underscore'),
    extend = require('config-extend'),
    path = require('path');

exports.getGithubUrl = function(options) {
  return function(next) {
    console.log('starting getGithubUrl');
    if (/^git@github\.com/.test(options.template)) {
      next(null, options.template);
    } else if (~options.template.indexOf('/')) {
      next(null, 'git@github.com:' + options.template + '.git');
    } else {
      request.get('https://registry.npmjs.org/' + options.template + '/latest', function(err, res, body) {
        if (err) next(err, null);
        else if (!body) next('https://registry.npmjs.org timed out processing the request', null);
        else {
          console.log('finished getGithubUrl');
          next(null, body.homepage.replace('https://github.com/', 'git@github.com:') + '.git');
        }
      });
    }
  };
};

exports.clone = function(options) {
  return function(next, dependencies) {
    cp.exec('git clone ' + dependencies.getGithubUrl + ' ' + options.repoName, { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
      if (err) next(err);
      else if (stderr) next(stderr);
      else {
        console.log('Cloned ' + dependencies.getGithubUrl);
        console.log('finished clone');
        next(null);
      }
    });
  };
};

exports.findInterpolation = function(options) {
  return function(next) {
    console.log('starting findInterpolation');
    var files = '';
    var pattern = [options.interpolate, options.evaluate, options.escape].join('|');
    var grep = cp.spawn('grep', ['-rlP', pattern, options.cwd]);
    grep.stdout.on('data', function(data) {
      files += data.toString();
    });
    grep.on('close', function() {
      console.log('finished findInterpolation');
      next(null, files.split('\n'));
    });
  };
};

exports.replaceInterpolation = function(options) {
  return function(next, dependencies) {
    console.log('starting replaceInterpolation');
    async.each(dependencies.findInterpolation, function(file, cb) {
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
        console.log('finished replaceInterpolation');
        next();
      }
    });
  };
};

exports.read = function(file) {
  return function(next) {
    console.log('starting read');
    fs.readFile(file, function(err, data) {
      if (err) next(err);
      else {
        console.log('finished read');
        next(null, data);
      }
    });
  };
};

exports.replace = function(options) {
  return function(data, next) {
    console.log('starting replace');
    _.templateSettings = {
      interpolate: new RegExp(options.interpolate, 'g'),
      evaluate: new RegExp(options.evaluate, 'g'),
      escape: new RegExp(options.escape, 'g')
    };
    console.log('finished replace');
    next(null, _.template(data, options));
  };
};

exports.write = function(file) {
  return function(data, next) {
    console.log('starting write');
    fs.writeFile(file, data, next);
  };
};

exports.createRepo = function(options) {
  return function(next) {
    console.log('starting createRepo');
    var json = {
      name: options.repoName,
      description: options.description || '',
      private: !!options.private,
      has_wiki: !!options.wiki,
      has_issues: !!options.issues
    };
    request.post('https://api.github.com/user/repos', { json: json, auth: { user: options.user } }, function(err, res, body) {
      if (err) next(err);
      else if (!body) next('https://api.github.com timed out processing the request', null);
      else {
        extend(options, { repo: body });
        console.log('Created new repo at ' + options.repo.html_url);
        console.log('finished createRepo');
        next();
      }
    });
  };
};

exports.createRemote = function(options) {
  return function(next) {
    console.log('starting createRemote');
    cp.exec('git remote add origin ' + options.repo.clone_url, { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        console.log('Created remote', 'origin'.blue, 'at', options.repo.clone_url.blue);
        console.log('finished createRemote');
        next();
      }
    });
  };
};
 
exports.add = function(options) {
  return function(next) {
    console.log('starting add');
    cp.exec('git add .', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        console.log('finished add');
        next();
      }
    });
  };
};

exports.commit = function(options) {
  return function(next) {
    console.log('starting commit');
    cp.exec('git commit -m "Initial commit using tinder template ' + options.template + '"', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        console.log('finished commit');
        next();
      }
    });
  };
};

exports.push = function(options) {
  return function(next) {
    console.log('starting push');
    cp.exec('git push origin master', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
      if (err || stderr) next(err || stderr);
      else {
        console.log('finished push');
        next();
      }
    });
  };
};

exports.chdir = function(options) {
  return function(next) {
    process.chdir(options.repoName);
  };
};
