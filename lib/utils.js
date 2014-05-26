var request = require('request'),
    async = require('async'),
    cp = require('child_process'),
    fs = require('fs'),
    _ = require('underscore'),
    extend = require('config-extend'),
    path = require('path');

exports.create = function(options) {
  return {
    getGithubUrl: function(next) {
      console.log('getGithubUrl');
      if (/^git@github\.com/.test(options.template)) next(null, options.template);
      else if (~options.template.indexOf('/')) next(null, 'git@github.com:' + options.template + '.git');
      else {
        request.get('https://registry.npmjs.org/' + options.template + '/latest', function(err, res, body) {
          if (err) next(err, null);
          else if (res.statusCode !== 200) {
            if (res.statusCode === 404) next(null, 'git@github.com:' + options.user + '/' + options.template + '.git');
            else next('https://registry.npmjs.org/' + options.template + '/latest responded with status code ' + res.statusCode, null);
          }
          else next(null, body.homepage.replace('https://github.com/', 'git@github.com:') + '.git');
        });
      }
    },

    clone: function(next, dependencies) {
      console.log('clone');
      cp.exec('git clone ' + dependencies.getGithubUrl + ' ' + options.repoName, { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
        if (err) next(err);
        else if (stderr) next(stderr);
        else {
          console.log('Cloned ' + dependencies.getGithubUrl);
          next(null);
        }
      });
    },

    findInterpolation: function(next) {
      console.log('findInterpolation');
      var files = '';
      var pattern = [options.interpolate, options.evaluate, options.escape].join('|');
      var grep = cp.spawn('grep', ['-rlP', pattern, options.cwd]);
      grep.stdout.on('data', function(data) {
        files += data.toString();
      });
      grep.on('close', function() {
        next(null, files.split('\n').filter(function(file) {
          return file.trim() !== '';
        }));
      });
    },

    replaceInterpolation: function(next, dependencies) {
      console.log('replaceInterpolation');
      async.each(dependencies.findInterpolation, function(file, cb) {
        var r = exports.replace(file, options);
        async.waterfall([r.read, r.replace, r.write], function(err) {
          if (err) cb(err);
          else cb();
        });
      }, function(err) {
        if (err) next(err);
        else next();
      });
    },

    createRepo: function(next) {
      console.log('createRepo');
      var json = {
        name: options.repoName,
        description: options.description || '',
        private: !!options.private,
        has_wiki: !!options.wiki,
        has_issues: !!options.issues
      };
      var auth = {
        user: options.user,
        pass: options.pass
      };
      request.post('https://api.github.com/user/repos', { json: json, auth: auth }, function(err, res, body) {
        if (err) next(err);
        else if (!body) next('https://api.github.com timed out processing the request', null);
        else {
          extend(options, { repo: body });
          console.log('Created new repo at ' + options.repo.html_url);
          next();
        }
      });
    },

    createRemote: function(next) {
      console.log('createRemote');
      cp.exec('git remote add origin ' + options.repo.clone_url, { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
        if (err || stderr) next(err || stderr);
        else {
          console.log('Created remote', 'origin'.blue, 'at', options.repo.clone_url.blue);
          next();
        }
      });
    },
 
    add: function(next) {
      console.log('add');
      cp.exec('git add .', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
        if (err || stderr) next(err || stderr);
        else next();
      });
    },

    commit: function(next) {
      console.log('commit');
      cp.exec('git commit -m "Initial commit using tinder template ' + options.template + '"', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
        if (err || stderr) next(err || stderr);
        else next();
      });
    },

    push: function(next) {
      console.log('push');
      cp.exec('git push origin master', { stdio: 'inherit', cwd: options.cwd }, function(err, stdout, stderr) {
        if (err || stderr) next(err || stderr);
        else next();
      });
    },

    chdir: function(next) {
      console.log('chdir');
      process.chdir(options.repoName);
      next();
    }
  };
};

exports.replace = function(file, options) {
  return {
    read: function(next) {
      fs.readFile(file, 'utf8', function(err, data) {
        if (err) next(err);
        else next(null, data);
      });
    },

    replace: function(data, next) {
      _.templateSettings = {
        interpolate: new RegExp(options.interpolate, 'g'),
        evaluate: new RegExp(options.evaluate, 'g'),
        escape: new RegExp(options.escape, 'g')
      };
      next(null, _.template(data, options));
    },

    write: function(data, next) {
      fs.writeFile(file, data, next);
    }
  };
};
