var program = require('commander');
var Module = require('./lib/module');
var App = require('./lib/app');

program
  .version(require('./package').version);

program
  .command('app')
  .description('initialize a new express app')
  .action(new App(program).init);

program
  .command('module')
  .description('initialize a new module')
  .action(new Module(program).init);
