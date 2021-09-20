 const { series } = require('gulp');
 const chalk = require('chalk');

 require('./tasks');

 const buildMode = process.env.KRAKEN_BUILD || 'Debug';

 // Run tasks
 series(
  //  'windows-dll-clean',
   'compile-polyfill',
  //  'build-windows-kraken-lib',
 )((err) => {
   if (err) {
     console.log(err);
   } else {
     console.log(chalk.green('Success.'));
   }
 });
