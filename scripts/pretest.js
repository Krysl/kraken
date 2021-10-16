const { spawnSync, execSync, fork, spawn, exec } = require('child_process');
const os = require('os');
const path = require('path');

const platform = os.platform();

let script;
if (platform === 'win32') {
  script = 'build_windows_dll';
} else if (platform === 'darwin') {
  script = 'build_darwin_dylib';
}

script = path.resolve(__dirname, script);

execSync(`node ${script}`);
