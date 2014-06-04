var request = require('request'),
    async = require('async'),
    cp = require('child_process'),
    fs = require('fs'),
    _ = require('underscore'),
    extend = require('config-extend'),
    tilde = require('tilde-expansion');

exports.create = function(options) {
  return {
    getGithubUrl: function(next) {
      if (/^git@github\.com/.test(options.template)) next(null, options.template);
      else if (~options.template.indexOf('/')) next(null, 'git@github.com:' + options.template + '.git');
      else {
        request.get('https://registry.npmjs.org/' + options.template + '/latest', function(err, res, body) {
          if (err) next(err, null);
          else if (res.statusCode > 299) {
            if (res.statusCode === 404) next(null, 'git@github.com:' + options.user + '/' + options.template + '.git');
            else next('https://registry.npmjs.org/' + options.template + '/latest responded with status code ' + res.statusCode, null);
          }
          else next(null, body.homepage.replace('https://github.com/', 'git@github.com:') + '.git');
        });
      }
    },

    clone: function(next, data) {
      var clone = cp.spawn('git', ['clone', data.getGithubUrl], { stdio: 'inherit' });
      clone.on('close', function(code) {
        if (code) next('git clone ' + data.getGithubUrl + ' returned code ' + code);
        else {
          console.log('Cloned ' + data.getGithubUrl);
          next();
        }
      });
    },

    copy: function(next, data) {
      var dir = options.clonedDir = _(data.getGithubUrl.split('/')).last().split('.')[0];
      var copy = cp.spawn('cp', ['-Ri', dir + '/template', options.repoName], { stdio: 'inherit' });
      copy.on('close', function(code) {
        if (code) next('cp -Ri ' + dir + '/template ' + options.repoName + ' returned code ' + code);
        else next();
      });
    },

    findInterpolation: function(next) {
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

    replaceInterpolation: function(next, data) {
      async.each(data.findInterpolation, function(file, cb) {
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
      var opts = {
        json: {
          name: options.repoName,
          description: options.description || '',
          private: !!options.private,
          has_wiki: !!options.wiki,
          has_issues: !!options.issues
        },
        auth: {
          user: options.user,
          pass: options.pass
        },
        headers: {
          'User-Agent': options.repoName
        }
      };
      request.post('https://api.github.com/user/repos', opts, function(err, res, body) {
        if (err) next(err);
        else if (res.statusCode > 299) next('https://api.github.com/user/repos responded with status code ' + res.statusCode, null);
        else {
          extend(options, { repo: body });
          console.log('Created new repo at ' + options.repo.html_url.green);
          next();
        }
      });
    },

    createRemote: function(next) {
      var remote = cp.spawn('git', ['remote', 'set-url', 'origin', options.repo.clone_url], { stdio: 'inherit', cwd: options.cwd });
      remote.on('close', function(code){
        if (code) next('git remote set-url origin ' + options.repo.clone_url + ' returned code ' + code);
        else {
          console.log('Set remote', 'origin'.green, 'to', options.repo.clone_url.green);
          next();
        }
      });
    },
 
    add: function(next) {
      var add = cp.spawn('git', ['add', '.'], { stdio: 'inherit', cwd: options.cwd });
      add.on('close', function(code){
        if (code) next('git add . returned code ' + code);
        else next();
      });
    },

    commit: function(next) {
      var commit = cp.spawn('git', ['commit', '-m', 'Initial commit using tinder template ' + options.template], { stdio: 'inherit', cwd: options.cwd });
      commit.on('close', function(code){
        if (code) next('git commit -m "Initial commit using tinder template ' + options.template + '" returned code ' + code);
        else next();
      });
    },

    push: function(next) {
      var push = cp.spawn('git', ['push', 'origin', 'master'], { stdio: 'inherit', cwd: options.cwd });
      push.on('close', function(code) {
        if (code) next('git push origin master returned code ' + code);
        else next();
      });
    },

    cleanup: function(next) {
      var rm = cp.spawn('rm', ['-rf', options.clonedDir], { stdio: 'inherit' });
      rm.on('close', function(code) {
        if (code) next('Unable to delete temporary directory ./' + options.clonedDir);
        else next();
      });
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

exports.config = function(options) {
  return {
    fetch: function(cb) {
      var requireConfig = function(confLocation) {
        fs.exists(confLocation, function(exists) {
          if (exists) {
            try {
              cb(null, require(confLocation));
            } catch (e) {
              cb(e);
            }
          } else {
            cb(null, {});
          }
        });
      };
      if (options.config) {
        requireConfig(options.config);
      } else {
        tilde('~/.tinder.json', function(file) {
          requireConfig(file);
        });
      }
    },

    update: function(cb, data) {
      if (options.user) {
        data.config.user = options.user;
      }
      if (options.template) {
        data.templates = (data.templates || []).concat(options.template);
      }
    }
  };
};
