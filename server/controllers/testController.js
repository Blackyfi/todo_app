const { exec } = require('child_process');
const path = require('path');
const ApiResponse = require('../utils/response');
const logger = require('../utils/logger');

/**
 * Run tests via API endpoint
 */
async function runTests(req, res, next) {
  try {
    const { testFile } = req.body;
    const projectRoot = path.join(__dirname, '..');

    let command = 'npm test';
    if (testFile) {
      command = `npm test -- ${testFile}`;
    }

    logger.info('Running tests', { testFile: testFile || 'all' });

    exec(
      command,
      {
        cwd: projectRoot,
        env: { ...process.env, NODE_ENV: 'test' },
        maxBuffer: 1024 * 1024 * 10, // 10MB buffer
      },
      (error, stdout, stderr) => {
        const output = stdout + stderr;

        if (error && !output.includes('Tests:')) {
          // Real error (not just test failures)
          logger.error('Test execution error', { error: error.message });
          return ApiResponse.error(res, 'Failed to run tests', 500, { error: error.message });
        }

        // Tests ran (may have failures, but that's okay)
        logger.info('Tests completed', {
          hasFailures: output.includes('failed'),
        });

        return ApiResponse.success(res, { output });
      }
    );
  } catch (error) {
    next(error);
  }
}

module.exports = {
  runTests,
};
