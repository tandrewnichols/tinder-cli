var taskMaster = require('task-master');

module.exports = function(grunt) {
  taskMaster(grunt);

  grunt.registerTask('default', ['test']);
};
