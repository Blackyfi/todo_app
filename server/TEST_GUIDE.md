# Quick Test Guide

## 🚀 Fastest Way to Run Tests

### Option 1: Web UI (Easiest!)

1. Start the server:
   ```bash
   npm start
   ```

2. Open in browser:
   ```
   https://localhost:8443/tests.html
   ```

3. Click "Run All Tests" button

That's it! Watch tests run in real-time in the browser.

---

### Option 2: Command Line

```bash
# Run all tests
npm test

# Run specific test file
npm test user.test.js
npm test task.test.js
npm test validation.test.js

# Run with coverage report
npm test -- --coverage

# Watch mode (re-run on file changes)
npm test -- --watch
```

---

## 📊 Available Test Suites

### 1. User Tests (user.test.js)
- ✅ User creation
- ✅ Password hashing
- ✅ Password verification
- ✅ Username uniqueness
- ✅ User statistics

**Run:** `npm test user.test.js`

### 2. Task Tests (task.test.js)
- ✅ Task creation (upsert)
- ✅ Task updates
- ✅ Conflict resolution (last-write-wins)
- ✅ Task statistics
- ✅ Soft delete handling

**Run:** `npm test task.test.js`

### 3. Validation Tests (validation.test.js)
- ✅ Username validation (3-30 chars, alphanumeric)
- ✅ Email validation (format checking)
- ✅ Password strength (8+ chars, upper, lower, number)
- ✅ Error message generation

**Run:** `npm test validation.test.js`

### 4. Encryption Tests (encryption.test.js)
- ✅ JWT token generation
- ✅ JWT token verification
- ✅ Token hashing (SHA-256)
- ✅ Invalid token handling

**Run:** `npm test encryption.test.js`

---

## 🌐 Accessing the Web UI

### Dashboard (Main)
```
https://localhost:8443/index.html
OR
https://localhost:8443/
```

**Features:**
- Real-time server statistics
- User, device, and sync metrics
- Database statistics
- Auto-refresh every 30 seconds

### Test Runner
```
https://localhost:8443/tests.html
```

**Features:**
- Run all tests or individual suites
- Real-time output display
- Test summary (passed/failed/duration)
- Color-coded results
- Clear test documentation

---

## 📝 Test Output Examples

### Successful Test Run
```
PASS tests/unit/user.test.js
  User Model
    ✓ should create a new user (45ms)
    ✓ should find user by username (12ms)
    ✓ should verify correct password (87ms)
    ✓ should reject incorrect password (86ms)
    ✓ should throw error for duplicate username (15ms)
    ✓ should get user statistics (8ms)

Tests:       6 passed, 6 total
Time:        2.567s
```

### Failed Test Example
```
FAIL tests/unit/task.test.js
  Task Model
    ✓ should upsert new task (15ms)
    ✗ should update existing task (25ms)

    Expected: "Updated Title"
    Received: "Original Title"

Tests:       1 failed, 1 passed, 2 total
```

---

## 🔧 Test Configuration

Tests use **in-memory SQLite database** (`:memory:`), so:
- ✅ No pollution of production database
- ✅ Fast execution (no disk I/O)
- ✅ Clean state for each test
- ✅ Parallel test execution possible

Configuration file: `jest.config.js`

---

## 📦 Dependencies

Tests require:
- **jest** - Testing framework
- **better-sqlite3** - In-memory database for tests

Already included in `package.json` dev dependencies!

---

## 🎯 Quick Commands Cheat Sheet

```bash
# Install dependencies (if not done)
npm install

# Run all tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run specific test
npm test user.test.js

# Watch mode
npm test -- --watch

# Verbose output
npm test -- --verbose

# Run tests in web UI
npm start
# Then open: https://localhost:8443/tests.html
```

---

## 🐛 Troubleshooting

### "Cannot find module 'jest'"
```bash
npm install
```

### "Database locked"
Tests use in-memory DB, this shouldn't happen. If it does:
```bash
# Ensure no other tests are running
pkill -f jest
```

### Web UI shows "Failed to run tests"
```bash
# Make sure server is running
npm start

# Check server logs
tail -f logs/combined-*.log
```

### SSL Certificate Warning
This is normal for self-signed certificates. Click "Advanced" → "Proceed to localhost".

---

## 📊 Coverage Report

After running `npm test -- --coverage`:

- **coverage/** directory created
- **coverage/lcov-report/index.html** - Open in browser for detailed report
- Terminal shows coverage summary

**Target Coverage:**
- Statements: 50%+
- Branches: 50%+
- Functions: 50%+
- Lines: 50%+

---

## 🎨 Web UI Features

### Dashboard (`/index.html`)
- Server metrics (uptime, memory, CPU)
- User statistics (total, active, new)
- Device statistics (total, active, by type)
- Sync statistics (total, success rate)
- Database statistics (tasks, completion rate)

### Test Runner (`/tests.html`)
- Run all tests button
- Individual test suite buttons
- Real-time output with color coding
- Test summary cards
- Clear output button
- Test documentation

---

## ✨ Tips

1. **Use Web UI for quick testing** - Visual feedback is easier than terminal
2. **Use watch mode during development** - Auto-run tests on code changes
3. **Check coverage regularly** - Aim for high test coverage
4. **Run tests before commits** - Catch bugs early
5. **Web UI is great for demos** - Show stakeholders test results

---

## 🔗 Quick Links

- **Dashboard**: https://localhost:8443/index.html
- **Test Runner**: https://localhost:8443/tests.html
- **Health Check**: https://localhost:8443/api/health
- **API Docs**: `/opt/todo_app/server/docs/API.md`

---

**Happy Testing! 🎉**
