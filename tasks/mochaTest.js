module.exports = {
  test: {
    options: {
      reporter: 'spec',
      ui: 'mocha-given',
      require: 'coffee-script/register'
    },
    src: ['test/**/*.coffee']
  }
};
