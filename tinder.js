#!/usr/bin/env node

var program = require('commander');
var cli = require('./lib/cli');
var coercion = require('./lib/coercion');

program
  .version(require('./package').version)
  .usage('<command> <name> [options]')
  .option('-b, --base-dir [dir]', 'OS path or git url to base project', '~/tinder')
  .option('-d, --description [description]', 'description of the project')
  .option('-a, --author [name]', 'author name')
  .option('-e, --email', 'email of author')
  .option('-g, --github-account', 'github account name')
  .option('-k, --keywords [keyword]', 'keywords for package.json', coercion.list, [])
  .option('-r, --dependencies [module]', 'dependencies to be added to package.json', coercion.list, [])
  .option('-t, --dev-dependencies [module]','devDependencies to be added to package.json', coercion.list, [])
  .option('-n, --no-extend', 'replace dependencies rather than extending')
  .option('-v, --vars', 'Additional variables for template interpolation', coercion.obj, {})
  .option('--no-clean', 'do not rm -rf on a faiure');

program.name = 'tinder';

program
  .command('new <name>')
  .alias('mk')
  .description('initialize a new express app')
  .action(cli.create);

program.parse(process.argv);
