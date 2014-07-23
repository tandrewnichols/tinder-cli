var taskMaster = require('task-master');

module.exports = function(grunt) {
  grunt.initConfig(taskMaster(grunt));

  //grunt.registerTask('default', ['spec']);
};
