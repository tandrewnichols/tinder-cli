#!/usr/bin/env node

var program = require('commander'),
    cli = require('./lib/cli'),
    colors = require('colors'),
    coercion = require('./lib/coercion');

program
  .version(require('./package').version)
  .usage('<command> <name> [options]')
  .option('-b, --base-dir <dir>', 'OS path or git url to base project', '~/tinder')
  .option('-d, --description <description>', 'description of the project')
  .option('-k, --keywords <keyword>', 'keywords for package.json', coercion.list, [])
  .option('-i, --remove-deps <module>', 'Dependencies in base project to ignore', coercion.list, [])
  .option('-n, --no-extend', 'replace dependencies rather than extending')
  .option('-v, --vars <key>:<value>', 'Additional variables for template interpolation', coercion.obj, {})
  .option('--no-clean', 'do not rm -rf on a faiure');

program.name = 'tinder';

program
  .command('new <name>')
  .alias('mk')
  .description('initialize a new express app')
  .action(cli.create);

program.parse(process.argv);
