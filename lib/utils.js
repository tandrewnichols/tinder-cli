var fs = require('fs'),
    _ = require('underscore'),
    tilde = require('tilde-expansion');

//exports.config = function(options) {
  //return {
    //fetch: function(cb) {
      //var requireConfig = function(confLocation) {
        //fs.exists(confLocation, function(exists) {
          //if (exists) {
            //try {
              //cb(null, require(confLocation));
            //} catch (e) {
              //cb(e);
            //}
          //} else {
            //cb(null, {});
          //}
        //});
      //};
      //if (options.config) {
        //requireConfig(options.config);
      //} else {
        //tilde('~/.tinder.json', function(file) {
          //requireConfig(file);
        //});
      //}
    //},

    //update: function(cb, data) {
      //_(['user', 'interpolate', 'evaluate', 'escape']).each(function(field) {
        //if (options[field]) {
          //data.config[field] = options[field];
        //}
      //});
      //if (options.template.length) {
        //_(options.template).reduce(function(config, template) {
          //config.templates = config.templates || {};
          //config.templates[template.key] = {
            //name: template.name,
            //remote: template.remote,
            //vars: options.vars || {}
          //};
          //return config;
        //}, data.config);
      //} else if (options.vars) {
        //data.config.vars = options.vars;
      //}
      //cb();
    //}
  //};
//};
