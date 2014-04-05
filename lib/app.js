var App = module.exports = function App(options) {
  console.log(options);
  this.options = options;
};

App.prototype.init = function() {
  console.log('init called\n');
  console.log(JSON.parse(this.options, null, 4));
};
