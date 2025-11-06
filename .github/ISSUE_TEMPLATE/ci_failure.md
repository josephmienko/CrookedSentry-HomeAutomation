---
name: CI Failure Report
about: Report a failing CI workflow
title: '[CI] '
labels: ci, bug
assignees: ''

---

## Workflow Information

**Workflow Name:** (e.g., CI, Nightly Build, PR Checks)

**Run Number:** (Link to failed workflow run)

**Branch:** (e.g., main, develop, feature/xyz)

**Commit SHA:** (First 7 characters)

## Failure Details

**Failed Job:** (e.g., Build and Analyze, Run Tests)

**Error Message:**
```
Paste error message here
```

**Failed Test(s):** (if applicable)
- Test suite: 
- Test case:

## Reproduction

**Can you reproduce locally?**
- [ ] Yes, consistently
- [ ] Yes, intermittently  
- [ ] No, only fails on CI

**Steps to reproduce locally:**
1. 
2. 
3. 

## Environment

**Xcode Version:** (from CI logs)

**Simulator:** (e.g., iPhone 15, iOS 17.5)

**macOS Runner:** (e.g., macos-14)

## Artifacts

**Did you download xcresult?**
- [ ] Yes (attach key findings)
- [ ] No
- [ ] Not available

## Additional Context

Add any other context about the problem here.

## Potential Cause

If you have investigated, what do you think might be causing this?

## Related Issues

Link to related issues or PRs if applicable.
