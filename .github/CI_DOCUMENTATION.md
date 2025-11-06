# GitHub Actions CI/CD Pipeline

This repository uses GitHub Actions for continuous integration and deployment.

## Workflows Overview

### 1. **CI Pipeline** (`.github/workflows/ci.yml`)
Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**
- **Build**: Compiles the CrookedSentry app
- **Test**: Runs unit tests on multiple iPhone simulators (iPhone 15, iPhone 15 Pro Max)
- **UI Test**: Runs UI tests (on PRs and main branch only)
- **Code Quality**: Runs static analyzer and checks for TODOs/FIXMEs
- **Coverage**: Generates code coverage reports and uploads to Codecov
- **Security Scan**: Checks for hardcoded credentials and security-related TODOs

**Key Features:**
- Matrix testing across multiple device types
- Code coverage with Codecov integration
- Static analysis
- Test result artifacts

### 2. **PR Checks** (`.github/workflows/pr-checks.yml`)
Additional validation for pull requests.

**Jobs:**
- **PR Validation**: Checks PR title format, large files
- **Operational Mock Tests**: Runs OperationalMockIntegrationTests specifically
- **Changelog Check**: Reminds to update CHANGELOG.md

**Key Features:**
- Conventional commits validation
- Changed files linting
- Coverage diff analysis
- Focused security test suite

### 3. **Nightly Build** (`.github/workflows/nightly.yml`)
Scheduled daily at 2 AM UTC, also manually triggerable.

**Jobs:**
- **Comprehensive Test**: Matrix testing across multiple Xcode versions and devices
- **Performance Test**: Runs performance-specific test cases
- **Memory Leak Detection**: Uses Address Sanitizer to detect memory issues
- **Notify Results**: Summarizes all nightly job results

**Key Features:**
- Cross-version Xcode testing (15.4, 16.0)
- iPad testing
- Performance monitoring
- Memory leak detection

### 4. **Release** (`.github/workflows/release.yml`)
Triggers on version tags (e.g., `v1.0.0`).

**Jobs:**
- **Validate Tag**: Ensures semantic versioning format
- **Build Release**: Full test suite + release archive
- **Security Audit**: Comprehensive security test run

**Key Features:**
- Semantic version validation
- Automatic release notes generation
- GitHub release creation
- Security-focused testing
- 90-day artifact retention

### 5. **Coverage Report** (`.github/workflows/coverage.yml`)
Existing coverage-focused workflow.

## Configuration Requirements

### Secrets
Add these to your repository secrets (Settings → Secrets and variables → Actions):

- `CODECOV_TOKEN` (optional): For Codecov integration
  - Get from https://codecov.io after linking your repo

### Branch Protection
Recommended settings for `main` branch:

```
✓ Require pull request reviews before merging
✓ Require status checks to pass before merging
  - Build and Analyze
  - Run Tests
  - Code Quality Checks
✓ Require conversation resolution before merging
✓ Require linear history
```

## Usage Examples

### Running CI Locally
While CI runs automatically, you can approximate it locally:

```bash
# Build
xcodebuild build \
  -project CrookedSentry.xcodeproj \
  -scheme CrookedSentry \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test \
  -project CrookedSentry.xcodeproj \
  -scheme CrookedSentryTests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# Run specific test suite
xcodebuild test \
  -project CrookedSentry.xcodeproj \
  -scheme CrookedSentryTests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CrookedSentryTests/OperationalMockIntegrationTests
```

### Creating a Release

1. Ensure all tests pass on `main` branch
2. Update version in Xcode project
3. Update CHANGELOG.md
4. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
5. Release workflow will automatically:
   - Run full test suite
   - Create GitHub release
   - Generate release notes

### Manual Workflow Trigger

For the nightly build:
1. Go to Actions tab
2. Select "Nightly Build"
3. Click "Run workflow"
4. Choose branch and click "Run workflow"

## Test Suites

### Unit Tests
- `OperationalMockIntegrationTests`: Mock infrastructure validation
- `CameraFeedLoadingTests`: Camera feed functionality
- `SettingsStoreTests`: Settings management
- `FrigateEventAPIClientTests`: API client tests
- `InfrastructureMockTests`: Mock system tests

### Security Tests
- `SecurityIntegrationTests`: Overall security integration
- `SecureAPIClientTests`: Secure API functionality
- `NetworkSecurityValidatorTests`: Network security validation
- `VPNConnectionStateTests`: VPN connection management
- `NetworkSecurityDebuggerTests`: Security debugging tools

### UI Tests
- `CrookedSentryUITests`: Main UI test suite
- `CrookedSentryUITestsLaunchTests`: Launch performance tests

## Monitoring

### Check Workflow Status
- View in GitHub Actions tab
- Status badges can be added to README:
  ```markdown
  ![CI](https://github.com/josephmienko/CrookedSentry-HomeAutomation/workflows/CI/badge.svg)
  ```

### Coverage Reports
- Check Codecov dashboard after setting up integration
- PR comments show coverage changes
- Job summary shows detailed coverage report

### Performance Tracking
- Nightly builds track performance test results
- Results archived for 30 days
- Compare across Xcode versions

## Troubleshooting

### Simulator Issues
If tests fail with "failed to launch" errors:
- Usually resolved by GitHub Actions automatically
- Stable Xcode version (15.4) used to avoid beta issues
- If persistent, check Xcode version compatibility

### Test Timeouts
- Default test timeout is 120 seconds
- Adjust in workflow if needed for slower tests
- Performance tests may take longer

### Failed Builds
1. Check job logs in Actions tab
2. Download artifacts for detailed xcresult
3. Review specific test failures
4. Re-run failed jobs if transient

## Best Practices

### For Contributors
- Ensure tests pass locally before pushing
- Write tests for new features
- Update tests when modifying existing code
- Check PR checks before requesting review

### For Maintainers
- Review security scan results regularly
- Monitor nightly build results
- Update Xcode versions as needed
- Rotate secrets periodically

## Future Enhancements

Potential additions:
- [ ] SwiftLint integration
- [ ] Danger for PR automation
- [ ] TestFlight deployment
- [ ] Performance regression tracking
- [ ] Slack/Discord notifications
- [ ] Dependency update automation (Dependabot)
