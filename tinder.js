#!/usr/bin/env node

/*
 * NOTE: process.execPath points to where node is. Use process.execPath.replace('/node', '') to get the global install location
 */

var program = require('commander'),
    cli = require('./lib/cli'),
    colors = require('colors'),
    coercion = require('./lib/coercion');

program
  .version(require('./package').version)
  .usage('<command> <name> [options]');

program.name = 'tinder';

program
  .command('new <name> <template>')
  .alias('mk')
  .description('Initialize new project <name> based on <template>')
  .option('-d, --description <description>', 'description of the project')
  .option('-k, --keywords <keyword>', 'keywords for package.json', coercion.list, [])
  .option('-r, --remove-deps <module>', 'Dependencies in base project not to include', coercion.list, [])
  .option('-v, --vars <key>:<value>', 'Additional variables for template interpolation', coercion.obj, {})
  .option('--no-clean', 'do not rm -rf on a faiure')
  .action(cli.create);

program.parse(process.argv);
