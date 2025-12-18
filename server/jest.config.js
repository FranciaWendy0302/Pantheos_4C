module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: ['/node_modules/'],
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'routes/**/*.js',
    'websocket/**/*.js',
    'managers/**/*.js',
    '!**/node_modules/**'
  ],
  verbose: true
};
