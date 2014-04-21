var request = require('request');

exports.getGithubUrl = function(template, cb) {
  if (~template.indexOf('/')) {
    cb(null, 'git@github.com:' + template + '.git');
  } else {
    request.get('https://registry.npmjs.org/' + template, function(err, res, body) {
      if (err) cb(err, null);
      else if (!body) cb('Timeout', null);
      else {

      }
    });
  }
};







/*--------------------------------------------------*/

exports.extendOptionsFromFile = function(options) {
  if (options.optsFile) {
    try {
      var opts = require(path.resolve(options.optsFile));
      if (options.extend) {
        options.dependencies = options.dependencies.concat(opts.dependencies || []);
        options.devDependencies = options.devDependencies.concat(opts.devDependencies || []);
        delete opts.dependencies;
        delete opts.devDependencies;
      }
      extend(options, opts);
    } catch (e) {
      return;
    }
  }
};

exports.mkdir = function(name, cb) {
  fs.mkdir('./' + name, cb);
};

exports.gitUrls = function(options) {
  var location = options.githubAccount + '/' + options.name;
  options.cloneUrl = 'git@github.com:' + location + '.git';
  options.gitUrl = 'git://github.com/' + location;
  options.githubUrl = 'https://github.com/' + location;
};

exports.initializeGit = function(name, cloneUrl, cb) {
  process.chdir('./' + name);
  git.exec('init', function(err, msg) {
    if (err) {
      console.error(err);
      cb(err);
    } else {
      console.log(msg);
    }
    git.exec('remote', ['add', 'origin', cloneUrl], cb);
  });
};

exports.basePackage = function(options) {
  var package = {
    name: options.name,
    description: options.description,
    version: "0.0.1",
    author: {
      name: options.author,
      email: options.email
    },
    repository: {
      type: "git",
      url: options.gitUrl
    },
    homepage: options.githubUrl,
    bugs: {
      url: options.githubUrl + "/issues"
    },
    licenses: [
      {
        type: "MIT",
        url: options.githubUrl + "/blob/master/LICENSE"
      }
    ],
    main: options.main || "./index",
  };
  if (options.keywords) {
    package.keywords = options.keywords;
  }
  return extend(package, options.package);
};

exports.writePackage = function(package, cb) {
  fs.writeFile('./package.json', JSON.stringify(package, null, 4), cb);
};
      
exports.addDependencies = $('abf', function(deps, dev, cb) {
  cp.exec('npm install ' + deps.join(' ') + ' ' + (dev ? '--save-dev' : '--save') + ' --save-exact', function(err, stdout, stderr) {
    if (err) {
      console.error(err);
    } else if (stderr) {
      console.error(stderr);
    } else {
      console.log(stdout);
    }
    cb();
  });
});
