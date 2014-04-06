#!/usr/bin/env node

var program = require('commander');
var Module = require('./lib/module');
var App = require('./lib/app');
var coercion = require('./lib/coercion');

program
  .version(require('./package').version)
  .usage('<command> <name> [options]')
  .option('-o, --opts-file', 'path to tinder.opts', '~/tinder.json')
  .option('-d, --description', 'description of the project')
  .option('-a, --author', 'author name')
  .option('-e, --email', 'email of author')
  .option('-g, --github-account', 'github account name')
  .option('-k, --keywords [keyword]', 'keywords for package.json', coercion.list, [])
  .option('-r, --dependencies [module]', 'dependencies to be added to package.json', coercion.list, [])
  .option('-v, --dev-dependencies [module]','devDependencies to be added to package.json', coercion.list, [])
  .option('-n, --no-extend', 'replace dependencies rather than extending')
  .option('-m, --main', 'location of main file')
  .parse(process.argv);

program.name = 'tinder';

program
  .command('app <name>')
  .description('initialize a new express app')
  .action(new App(program).init);

program
  .command('module <name>')
  .description('initialize a new module')
  .action(new Module(program).init);
