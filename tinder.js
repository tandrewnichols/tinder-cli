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
  .command('new <name> <template>')
  .alias('mk')
  .description('Initialize new project <name> based on <template>')
  .option('-u, --user <username>', 'Github username')
  .option('-d, --description <description>', 'Description of the project')
  .option('-k, --keywords <keyword>', 'keywords for package.json', coercion.list, [])
  .option('-r, --remove-deps <module>', 'Dependencies in base project not to include', coercion.list, [])
  .option('-v, --vars <key>:<value>', 'Additional variables for template interpolation', coercion.obj, {})
  .option('-i, --interpolate <value>', 'Underscore interpolate pattern', _.templateSettings.interpolate.source)
  .option('-e, --evaluate <pattern>', 'Underscore evaluate pattern', _.templateSettings.evaluate.source)
  .option('--escape <pattern>', 'Underscore escape pattern', _.templateSettings.escape.source)
  .option('--no-clean', 'Do not rm -rf on a faiure')
  .option('--private', 'Create a private github repo')
  .option('--no-wiki', 'Do not create a github wiki')
  .option('--no-issues', 'Do not create a github issues page')
  .option('--auto-init', 'Auto-init github repo')
  .option('--gitignore <type>', 'Initialize repo with gitignore')
  .option('--license <type>', 'Initialize repo with license')
  .action(cli.create);

program.parse(process.argv);
