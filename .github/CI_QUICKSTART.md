# CI/CD Pipeline Overview

## Quick Reference

| Workflow | Trigger | Purpose | Duration |
|----------|---------|---------|----------|
| **CI** | Push/PR to main/develop | Build, test, quality checks | ~10-15 min |
| **PR Checks** | Pull requests | Additional PR validation | ~8-12 min |
| **Nightly** | Daily at 2 AM UTC | Comprehensive cross-version testing | ~30-45 min |
| **Release** | Version tags (v*.*.*) | Release preparation & security audit | ~15-20 min |
| **Coverage** | Push/PR to main | Detailed coverage reporting | ~10 min |

## Workflow Files

```
.github/workflows/
├── ci.yml              # Main CI pipeline
├── pr-checks.yml       # Pull request validation
├── nightly.yml         # Scheduled comprehensive tests
├── release.yml         # Release automation
└── coverage.yml        # Coverage reporting (existing)
```

## Key Features

### ✅ What's Automated

- **Building**: Automatic builds on every commit
- **Testing**: 
  - Unit tests across multiple iPhone/iPad simulators
  - Operational mock integration tests
  - Security-focused test suites
  - Performance tests (nightly)
  - Memory leak detection (nightly)
- **Quality**: 
  - Static code analysis
  - Coverage tracking with Codecov
  - Security scans for hardcoded credentials
- **Releases**:
  - Automated release notes from git commits
  - GitHub release creation
  - Semantic version validation

### 🎯 Testing Matrix

#### Standard CI (Every PR/Push)
- iPhone 15
- iPhone 15 Pro Max
- Xcode 15.4 (stable)

#### Nightly Build
- iPhone 15
- iPhone 15 Pro Max  
- iPad Pro 12.9"
- Xcode 15.4 + 16.0
- Address Sanitizer enabled

## Status Badges

Add these to your main README.md:

```markdown
![CI Status](https://github.com/josephmienko/CrookedSentry-HomeAutomation/workflows/CI/badge.svg)
![Coverage](https://codecov.io/gh/josephmienko/CrookedSentry-HomeAutomation/branch/main/graph/badge.svg)
![Nightly](https://github.com/josephmienko/CrookedSentry-HomeAutomation/workflows/Nightly%20Build/badge.svg)
```

## Setup Steps

### 1. Enable GitHub Actions
Already enabled in this repo.

### 2. Add Codecov Integration (Optional)
1. Visit https://codecov.io
2. Sign in with GitHub
3. Enable for this repository
4. Copy the token
5. Add as `CODECOV_TOKEN` in GitHub Secrets (Settings → Secrets)

### 3. Configure Branch Protection
Go to Settings → Branches → Add rule for `main`:

**Required Checks:**
- Build and Analyze
- Run Tests  
- Code Quality Checks

### 4. Test the Workflows
```bash
# Trigger CI
git push origin your-branch

# Trigger Release
git tag v1.0.0
git push origin v1.0.0

# Trigger Nightly (manual)
# Go to Actions tab → Nightly Build → Run workflow
```

## Common Scenarios

### Before Merging a PR
Check that these pass:
- ✅ Build and Analyze
- ✅ Run Tests (both iPhone variants)
- ✅ Code Quality Checks
- ✅ PR Validation
- ✅ Operational Mock Tests

### Before Creating a Release
1. Ensure main branch is green (all checks pass)
2. Update version number in Xcode project
3. Update CHANGELOG.md with changes
4. Create and push version tag
5. Release workflow will handle the rest

### If Tests Fail on CI but Pass Locally
1. Check Xcode version (CI uses 15.4 stable)
2. Check device simulator (CI uses iPhone 15)
3. Download xcresult artifact from failed job
4. Check for race conditions or timing issues
5. Ensure tests don't depend on local environment

## Artifacts & Logs

All workflows save artifacts for debugging:

| Artifact | Retention | Contents |
|----------|-----------|----------|
| test-results-* | 5 days | xcresult bundles |
| coverage-report | 30 days | JSON and text coverage |
| performance-results | 30 days | Performance test results |
| build-logs-* | 7 days | Full xcodebuild logs |
| release-build | 90 days | Release xcarchive |

Download from: Actions → Workflow run → Artifacts section

## Performance Notes

### Build Caching
Currently no caching implemented. Future enhancement:
- Cache DerivedData between runs
- Cache SPM packages (when added)

### Parallel Execution
- Test job runs in parallel across device matrix
- Nightly runs across Xcode versions in parallel
- Independent jobs run concurrently

### Cost Optimization
- macOS runners are used (required for iOS builds)
- Nightly limited to once per day
- UI tests only on PRs and main
- Coverage only on PRs and main

## Troubleshooting

### "Simulator failed to launch" errors
- Usually transient simulator issues
- Retry the workflow
- Already using stable Xcode to minimize this

### Tests timeout
- Default timeout: 120 seconds per test
- Check for hanging tests
- May need to increase for performance tests

### Coverage upload fails
- Check `CODECOV_TOKEN` secret is set
- Verify Codecov integration is active
- workflow continues even if coverage upload fails

## Need Help?

- 📖 Full documentation: `.github/CI_DOCUMENTATION.md`
- 🐛 Issues with CI: Check Actions tab for detailed logs
- 💬 Questions: Open an issue or discussion

## Metrics to Monitor

Track these over time:
- ⏱️ Build duration (target: < 10 min)
- 📊 Test coverage (target: > 80%)
- ✅ Test pass rate (target: 100%)
- 🎯 Performance test trends
- 🔒 Security scan findings

---

Last Updated: November 5, 2025
