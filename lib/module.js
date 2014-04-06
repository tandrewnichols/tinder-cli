var utils = require('./utils');

var Module = module.exports = function Module (options) {
  this.options = options;
};

Module.prototype.init = function() {
  console.log(arguments);
  utils.extendOptionsFromFile(this.options); 
  console.log(this.options);
};
