var utils = require('./utils');

var Module = module.exports = function Module (options) {
  this.options = options;
};

Module.prototype.init = function() {
  utils.extendOptionsFromFile(this.options); 
};
