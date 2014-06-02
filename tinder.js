#!/usr/bin/env node

var program = require('commander'),
    cli = require('./lib/cli'),
    colors = require('colors'),
    coercion = require('./lib/coercion'),
    _ = require('underscore');

program
  .version(require('./package').version)
  .usage('<command> <name> [options]');

program.name = 'tinder';

program
  .command('new <name> [template] [description]')
  .alias('mk')
  .description('Initialize new project <name> based on <template>')
  .option('-u --user <username>:[password]', 'Github username')
  .option('-p --pass', 'Github password')
  .option('-d --description <description>', 'Description of the project')
  .option('-t --template <name>', 'Template to base project on')
  .option('-v --vars <json>', 'Additional variables for template interpolation', coercion.obj, {})
  .option('-i --interpolate <value>', 'Underscore interpolate pattern', _.templateSettings.interpolate.source)
  .option('-e --evaluate <pattern>', 'Underscore evaluate pattern', _.templateSettings.evaluate.source)
  .option('-E --escape <pattern>', 'Underscore escape pattern', _.templateSettings.escape.source)
  .option('-c --no-clean', 'Do not rm -rf on a faiure')
  .option('-P --private', 'Create a private github repo')
  .option('-w --no-wiki', 'Do not create a github wiki')
  .option('-I --no-issues', 'Do not create a github issues page')
  .action(cli.create);

program
  .command('config')
  .description('Register options for later re-use')
  .option('-u --user <username>', 'Register github username')
  .option('-v --var <name>:[type]', 'Register a variable name with a given type', coercion.vars)
  .option('-t --template <name>', 'Register a template', coercion.list)
  .option('-i --interpolate <value>', 'Register an underscore interpolate pattern', _.templateSettings.interpolate.source)
  .option('-e --evaluate <pattern>', 'Register an underscore evaluate pattern', _.templateSettings.evaluate.source)
  .option('-E --escape <pattern>', 'Register an underscore escape pattern', _.templateSettings.escape.source)
  .action(cli.register);

program
  .command('*')
  .usage('tinder <name> <template> [description]')
  .description('Shortcut for "new"')
  .action(cli.create);

program.parse(process.argv);
