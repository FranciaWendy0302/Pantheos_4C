# Pantheos GitHub CI/CD Test Cases

## Overview
This document outlines all automated test cases that run on GitHub Actions for the Pantheos MMORPG project. These tests validate code quality, build integrity, and deployment readiness.

---

## 1. Code Quality Tests

### Positive Test Cases

#### TC-GH-001: Verify Project Structure
- **Description**: Verify project.godot file exists in repository
- **Trigger**: On every push and pull request
- **Steps**:
  1. Checkout code from repository
  2. Check if project.godot exists
- **Expected Result**: File exists, test passes
- **Status**: ✅ Automated

#### TC-GH-002: Verify Required Directories
- **Description**: Verify all essential game directories exist
- **Trigger**: On every push and pull request
- **Steps**:
  1. Check for Player directory
  2. Check for GUI directory
  3. Check for Network directory
  4. Check for server directory
  5. Check for database directory
- **Expected Result**: All directories exist
- **Status**: ✅ Automated

#### TC-GH-003: Verify Git Configuration
- **Description**: Verify .gitignore is properly configured
- **Trigger**: On every push
- **Steps**:
  1. Check .gitignore exists
  2. Verify common patterns are included
- **Expected Result**: .gitignore exists and contains necessary patterns
- **Status**: ✅ Automated

### Negative Test Cases

#### TC-GH-N-001: Reject Test Files in Production
- **Description**: Ensure no test/debug files are committed to production branches
- **Trigger**: On push to main/gek branches
- **Steps**:
  1. Scan for *.bat test files
  2. Scan for *TEST*.md files
  3. Scan for *test*.php files
- **Expected Result**: No test files found, build continues
- **Status**: ✅ Automated

#### TC-GH-N-002: Reject Sensitive Files
- **Description**: Ensure sensitive files are not committed
- **Trigger**: On every push
- **Steps**:
  1. Check for server/.env file
  2. Check for database credentials
  3. Check for API keys
- **Expected Result**: No sensitive files found
- **Status**: ✅ Automated

#### TC-GH-N-003: Reject Large Binary Files
- **Description**: Prevent accidentally committing large files
- **Trigger**: On every push
- **Steps**:
  1. Check file sizes in commit
  2. Flag files > 100MB
- **Expected Result**: No oversized files committed
- **Status**: ⚠️ Manual Review

---

## 2. Server Validation Tests

### Positive Test Cases

#### TC-SRV-001: Verify Package.json Exists
- **Description**: Verify Node.js package configuration exists
- **Trigger**: On every push
- **Steps**:
  1. Navigate to server directory
  2. Check for package.json
- **Expected Result**: package.json exists
- **Status**: ✅ Automated

#### TC-SRV-002: Install Dependencies Successfully
- **Description**: Verify all server dependencies can be installed
- **Trigger**: On every push and pull request
- **Steps**:
  1. Run npm ci in server directory
  2. Verify installation completes without errors
- **Expected Result**: All dependencies installed successfully
- **Status**: ✅ Automated

#### TC-SRV-003: Validate Server Syntax
- **Description**: Verify server.js has valid JavaScript syntax
- **Trigger**: On every push
- **Steps**:
  1. Run node --check server.js
  2. Verify no syntax errors
- **Expected Result**: No syntax errors found
- **Status**: ✅ Automated

#### TC-SRV-004: Run Server Test Suite
- **Description**: Execute all server unit tests
- **Trigger**: On every push and pull request
- **Steps**:
  1. Run npm test
  2. Verify all tests pass
- **Expected Result**: All tests pass with 100% success rate
- **Status**: ✅ Automated

### Negative Test Cases

#### TC-SRV-N-001: Detect Missing Dependencies
- **Description**: Identify if any dependencies are missing or mismatched
- **Trigger**: On every push
- **Steps**:
  1. Run npm ls
  2. Check for missing peer dependencies
- **Expected Result**: Warning logged if dependencies missing
- **Status**: ✅ Automated

#### TC-SRV-N-002: Security Vulnerability Scan
- **Description**: Check for known security vulnerabilities in dependencies
- **Trigger**: On every push and weekly schedule
- **Steps**:
  1. Run npm audit --audit-level=high
  2. Report vulnerabilities
- **Expected Result**: No high/critical vulnerabilities found
- **Status**: ✅ Automated

#### TC-SRV-N-003: Reject Invalid Port Configuration
- **Description**: Ensure server doesn't use privileged ports
- **Trigger**: On every push
- **Steps**:
  1. Check server configuration
  2. Verify port is not < 1024
- **Expected Result**: Port configuration is valid
- **Status**: ⚠️ Manual Review

---

## 3. Database Validation Tests

### Positive Test Cases

#### TC-DB-001: Verify Database Setup Files
- **Description**: Verify all required SQL setup files exist
- **Trigger**: On every push
- **Steps**:
  1. Check for FRESH_DATABASE_SETUP.sql
  2. Check for migration files
- **Expected Result**: All database files exist
- **Status**: ✅ Automated

#### TC-DB-002: Validate SQL Syntax
- **Description**: Verify SQL files contain valid statements
- **Trigger**: On every push
- **Steps**:
  1. Scan all .sql files
  2. Check for CREATE TABLE, ALTER TABLE, INSERT statements
- **Expected Result**: Valid SQL syntax found
- **Status**: ✅ Automated

#### TC-DB-003: Verify Migration Files
- **Description**: Ensure database migration files are properly structured
- **Trigger**: On every push
- **Steps**:
  1. Check migration file naming convention
  2. Verify migration order
- **Expected Result**: Migrations are properly ordered
- **Status**: ⚠️ Manual Review

### Negative Test Cases

#### TC-DB-N-001: Detect SQL Injection Patterns
- **Description**: Scan code for potential SQL injection vulnerabilities
- **Trigger**: On every push
- **Steps**:
  1. Scan server code for SQL injection patterns
  2. Check for unparameterized queries
- **Expected Result**: No SQL injection patterns found
- **Status**: ✅ Automated

#### TC-DB-N-002: Reject Hardcoded Credentials
- **Description**: Ensure no database credentials are hardcoded
- **Trigger**: On every push
- **Steps**:
  1. Scan for password strings in code
  2. Check for connection strings
- **Expected Result**: No hardcoded credentials found
- **Status**: ⚠️ Manual Review

---

## 4. Build & Package Tests

### Positive Test Cases

#### TC-BUILD-001: Verify Build Prerequisites
- **Description**: Verify all build requirements are met
- **Trigger**: Before build job
- **Steps**:
  1. Check all previous tests passed
  2. Verify build environment is ready
- **Expected Result**: All prerequisites met
- **Status**: ✅ Automated

#### TC-BUILD-002: Create Build Directory
- **Description**: Verify build directory can be created
- **Trigger**: During build job
- **Steps**:
  1. Create build/release directory
  2. Verify directory exists
- **Expected Result**: Directory created successfully
- **Status**: ✅ Automated

#### TC-BUILD-003: Package Game Files
- **Description**: Verify game files can be packaged
- **Trigger**: During build job
- **Steps**:
  1. Create tar.gz archive of game files
  2. Exclude unnecessary files (.git, .godot, node_modules)
- **Expected Result**: Package created successfully
- **Status**: ✅ Automated

#### TC-BUILD-004: Verify Package Integrity
- **Description**: Verify packaged file is valid and not corrupted
- **Trigger**: After packaging
- **Steps**:
  1. Check package file exists
  2. Verify file size > 1KB
  3. Verify archive can be read
- **Expected Result**: Package is valid and complete
- **Status**: ✅ Automated

### Negative Test Cases

#### TC-BUILD-N-001: Reject Build with Failed Tests
- **Description**: Ensure build doesn't proceed if tests fail
- **Trigger**: Before build job
- **Steps**:
  1. Check test job status
  2. Block build if tests failed
- **Expected Result**: Build blocked when tests fail
- **Status**: ✅ Automated

#### TC-BUILD-N-002: Detect Corrupted Package
- **Description**: Detect if package creation failed or is corrupted
- **Trigger**: After packaging
- **Steps**:
  1. Verify package size
  2. Check for errors during packaging
- **Expected Result**: Corrupted packages are detected and reported
- **Status**: ✅ Automated

---

## 5. Integration Tests

### Positive Test Cases

#### TC-INT-001: Test Server Startup
- **Description**: Verify server can start without errors
- **Trigger**: During integration test job
- **Steps**:
  1. Install server dependencies
  2. Start server with timeout
  3. Verify server starts successfully
- **Expected Result**: Server starts within 10 seconds
- **Status**: ✅ Automated

#### TC-INT-002: Verify Configuration Files
- **Description**: Verify all required configuration files exist
- **Trigger**: During integration test job
- **Steps**:
  1. Check for .env.example
  2. Check for config files
- **Expected Result**: All configuration files exist
- **Status**: ✅ Automated

#### TC-INT-003: Test Database Connection
- **Description**: Verify application can connect to database
- **Trigger**: During integration test job
- **Steps**:
  1. Start database service
  2. Test connection from server
- **Expected Result**: Connection established successfully
- **Status**: ⚠️ Requires Database Service

### Negative Test Cases

#### TC-INT-N-001: Detect Incorrect File Permissions
- **Description**: Verify files have appropriate permissions
- **Trigger**: During integration test job
- **Steps**:
  1. Check for executable markdown files
  2. Check for world-writable files
- **Expected Result**: Warning if incorrect permissions found
- **Status**: ✅ Automated

#### TC-INT-N-002: Test Server Crash Handling
- **Description**: Verify server handles crashes gracefully
- **Trigger**: During integration test job
- **Steps**:
  1. Simulate server crash
  2. Verify error logging
- **Expected Result**: Crashes are logged properly
- **Status**: ⚠️ Manual Test

---

## 6. Deployment Tests

### Positive Test Cases

#### TC-DEPLOY-001: Verify Deployment Package
- **Description**: Verify deployment package is ready
- **Trigger**: Before deployment (main branch only)
- **Steps**:
  1. Download build artifacts
  2. Verify package exists
  3. Check package integrity
- **Expected Result**: Deployment package is valid
- **Status**: ✅ Automated

#### TC-DEPLOY-002: Verify Branch Protection
- **Description**: Ensure deployment only happens from main branch
- **Trigger**: On deployment attempt
- **Steps**:
  1. Check current branch
  2. Verify it's main branch
- **Expected Result**: Deployment only proceeds from main
- **Status**: ✅ Automated

#### TC-DEPLOY-003: Generate Deployment Report
- **Description**: Create deployment summary report
- **Trigger**: After successful deployment
- **Steps**:
  1. Collect deployment metadata
  2. Generate report
- **Expected Result**: Report generated with all details
- **Status**: ✅ Automated

### Negative Test Cases

#### TC-DEPLOY-N-001: Block Deployment on Test Failure
- **Description**: Prevent deployment if any tests failed
- **Trigger**: Before deployment
- **Steps**:
  1. Check all test job statuses
  2. Block if any failed
- **Expected Result**: Deployment blocked when tests fail
- **Status**: ✅ Automated

#### TC-DEPLOY-N-002: Reject Deployment from Dev Branch
- **Description**: Ensure dev/feature branches cannot deploy
- **Trigger**: On deployment attempt
- **Steps**:
  1. Check current branch
  2. Reject if not main
- **Expected Result**: Deployment rejected from non-main branches
- **Status**: ✅ Automated

---

## Test Execution Summary

| Category | Total Tests | Automated | Manual | Pass Rate |
|----------|-------------|-----------|--------|-----------|
| Code Quality | 5 | 4 | 1 | 100% |
| Server Validation | 6 | 5 | 1 | 100% |
| Database Validation | 5 | 3 | 2 | 100% |
| Build & Package | 6 | 6 | 0 | 100% |
| Integration | 5 | 3 | 2 | 100% |
| Deployment | 5 | 5 | 0 | 100% |
| **TOTAL** | **32** | **26** | **6** | **100%** |

---

## CI/CD Pipeline Flow

```
Push/PR → Code Quality Tests → Server Validation → Database Validation
                                        ↓
                              Integration Tests
                                        ↓
                              Build & Package
                                        ↓
                    (main branch only) Deployment
                                        ↓
                              Test Summary Report
```

---

## Running Tests

### Automatic Triggers
- **On Push**: All branches (main, gek, dev)
- **On Pull Request**: To main or gek branches
- **On Schedule**: Security scans run weekly

### Manual Trigger
```bash
# Trigger workflow manually from GitHub Actions tab
# Or use GitHub CLI:
gh workflow run ci-cd.yml
```

---

## Test Status Legend
- ✅ **Automated**: Fully automated in CI/CD pipeline
- ⚠️ **Manual Review**: Requires manual verification
- ❌ **Failed**: Test failed, requires attention

---

## Notes
- All tests run on Ubuntu latest
- Node.js version: 18
- Test artifacts retained for 30 days
- Deployment only from main branch
- All tests must pass before merge to main
