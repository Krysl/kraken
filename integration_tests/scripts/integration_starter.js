const { spawn, spawnSync } = require('child_process');
const path = require('path');
const { startWsServer } = require('./ws_server');
const isPortReachable = require('is-port-reachable');
const os = require('os');

const platform = os.platform();
const buildType =
  platform === 'darwin' ?
    'macos' :
    platform === 'win32' ?
      'windows' :
      platform;

// Dart null safety error didn't report in dist binaries. Should run integration test with flutter run directly.
function startIntegrationTest() {
  const shouldSkipBuild = /skip\-build/.test(process.argv);
  if (!shouldSkipBuild) {
    console.log(`Building integration tests ${buildType} application from "lib/main.dart"...`);
    spawnSync('flutter', ['build', buildType, '--debug'], {
      stdio: 'inherit',
      shell: platform === 'win32'
    });
  }
  let testExecutablePath;
  switch (platform) {
    case 'darwin':
      testExecutablePath = '../build/macos/Build/Products/Debug/tests.app/Contents/MacOS/tests';
      break;
    case 'win32':
      testExecutablePath = '../build/windows/runner/Debug/integration_tests.exe';
      break;
    default:
      break;
  }

  const testExecutable = path.join(__dirname, testExecutablePath);
  const tester = spawn(testExecutable, [], {
    env: {
      ...process.env,
      shell: platform === 'win32',
      KRAKEN_ENABLE_TEST: 'true',
      KRAKEN_TEST_DIR: path.join(__dirname, '../')
    },
    cwd: process.cwd(),
    stdio: 'inherit'
  });
  tester.on('close', (code) => {
    process.exit(code);
  });
  tester.on('error', (error) => {
    console.error(error);
    process.exit(1);
  });
  tester.on('exit', (code, signal) => {
    if (code != 0) {
      process.exit(1);
    }
  });
}

(async () => {
  startIntegrationTest();
  const PORT = 8399;
  if (!await isPortReachable(PORT)) {
    startWsServer(PORT);
  }
})();
