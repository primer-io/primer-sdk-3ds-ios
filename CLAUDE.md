# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview
This is the Primer 3DS iOS SDK, a wrapper around the Netcetera ThreeDS_SDK for handling 3D Secure authentication in iOS applications. The SDK is distributed via CocoaPods and Swift Package Manager.

## Key Architecture

### SDK Structure
- **Main SDK**: `Sources/Primer3DS/Classes/` - Contains the Swift implementation
- **Binary Framework**: `Sources/Frameworks/ThreeDS_SDK.xcframework` - Vendored Netcetera 3DS SDK
- **Example App**: `Example/` - Sample iOS application with tests

### Core Components
- `Primer3DS.swift`: Main SDK class handling initialization and 3DS flow
- `Primer3DSSDKProvider.swift`: Wrapper around Netcetera's ThreeDS_SDK
- `Primer3DSStructures.swift`: Data structures and enums (Environment, DirectoryServerNetwork, etc.)
- `Primer3DSError.swift`: Error handling and error types
- `Primer3DSProtocols.swift`: Protocol definitions for the SDK interface

### Card Network Mapping
The SDK maps card schemes to Netcetera's specialized scheme constructors:
- VISA → `.visa()`
- MASTERCARD → `.mastercard()`
- AMEX → `.amex()`
- DINERS_CLUB → `.diners()`
- JCB → `.jcb()`
- CARTES_BANCAIRES → `.cb()`
- EFTPOS → `.eftpos()`
- UNIONPAY → `.union()`

## Build & Test Commands

### CocoaPods (Example project)
```bash
cd Example
pod install
bundle exec fastlane unit_tests
```

### Fastlane
```bash
# Run unit tests with iPhone 14 Pro simulator
bundle exec fastlane unit_tests

# Tests run on: platform=iOS Simulator,name=iPhone 14 Pro
# Excludes arm64 architecture for simulator builds
```

### Manual Testing
```bash
cd Example
pod install
open Primer3DS.xcworkspace
# Run tests: Cmd+U with scheme "Primer3DS-Example"
```

## Development Configuration

### Environment Variables (CI/CD)
- `SOURCE_BRANCH`: Branch name for versioning
- `PR_NUMBER`: Pull request number
- `GITHUB_RUN_ID`, `GITHUB_RUN_NUMBER`: GitHub Actions identifiers

### Deployment Targets
- iOS 13.0+ (defined in Package.swift and Podspec)
- Swift 5.0+
- Xcode 15.0 (CI uses this version)

## Version Management
- Version is defined in `Primer3DS.podspec` (current: 2.8.0)
- Also tracked in `Sources/Primer3DS/Classes/version.swift`
- Version utilities in `VersionUtils.swift` handle SDK version numbers

## CI/CD Workflows

### Pull Request Requirements
- PR titles must follow conventional commits (fix:, feat:, chore:, or BREAKING CHANGE:)
- Danger runs to check PR formatting
- Tests run automatically on PR open/edit/sync

### GitHub Actions
- **build_test.yml**: Runs on PRs - Danger checks, then builds and tests
- **create_release.yml**: Creates releases
- **post-release-merge.yml**: Handles post-release merges

## Testing Approach
- Unit tests in `Example/Tests/`
- Mock implementations for SDK provider testing
- Tests cover initialization, 3DS challenges, error handling, and utilities
- No linting tool is currently configured (no SwiftLint)

## Important Notes
- Non-production environments use test certificates and override scheme configuration
- Production environment skips certificate overrides
- SDK delegates app lifecycle methods must be called from AppDelegate
- ThreeDS_SDK.xcframework is vendored and not built from source