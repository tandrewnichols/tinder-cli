module.exports = function(grunt) {
  grunt.registerTask('test', 'mochaTest');

  return {
    test: {
      options: {
        reporter: 'spec',
        ui: 'mocha-given',
        require: 'coffee-script/register'
      },
      src: ['test/**/*.coffee']
    }
  };
};
