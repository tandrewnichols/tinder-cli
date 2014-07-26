var taskMaster = require('task-master');

module.exports = function(grunt) {
  taskMaster(grunt);
  grunt.registerTask('publish', function(t) {
    grunt.task.run(['env:github', 'release' + (t ? ':' + t : '')]);
  });
};
