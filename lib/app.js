var utils = require('./utils');

var App = module.exports = function App(options) {
  this.options = options;
};

App.prototype.init = function() {
  utils.extendOptionsFromFile(this.options); 
};
