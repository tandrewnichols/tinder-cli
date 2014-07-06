var cp = require('child_process'),
    fs = require('fs');

exports.findInterpolation = function(options, next) {
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
};

exports.replaceInterpolation = function(options, next, data) {
  async.each(data.findInterpolation, function(file, cb) {
    var r = exports.replace(file, options);
    async.waterfall([
      exports.read.bind(exports, file, options),
      exports.replace.bind(exports, file, options),
      exports.write.bind(exports, file, options)
    ], function(err) {
      if (err) cb(err);
      else cb();
    });
  }, function(err) {
    if (err) next(err);
    else next();
  });
};

exports.read = function(file, options, next) {
  fs.readFile(file, 'utf8', function(err, data) {
    if (err) next(err);
    else next(null, data);
  });
};

exports.replace = function(file, options, data, next) {
  _.templateSettings = {
    interpolate: new RegExp(options.interpolate, 'g'),
    evaluate: new RegExp(options.evaluate, 'g'),
    escape: new RegExp(options.escape, 'g')
  };
  next(null, _.template(data, options));
};

exports.write = function(file, options, data, next) {
  fs.writeFile(file, data, next);
};
