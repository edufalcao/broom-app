# Contributing to Broom

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. Clone the repo
2. Install [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the Xcode project: `xcodegen generate`
4. Open `Broom.xcodeproj` in Xcode
5. Build and run (Cmd+R)

## Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run the tests: `xcodebuild -scheme Broom test`
5. Commit with a clear message
6. Push and open a Pull Request

## Guidelines

- Follow Swift standard conventions
- Write tests for new functionality
- Keep the app lightweight and focused
- Never add telemetry or analytics
- All PRs require one review

## Reporting Issues

Use the GitHub issue templates for:
- **Bug reports**: Include macOS version, Broom version, and steps to reproduce
- **Feature requests**: Describe the problem and proposed solution

## Code of Conduct

Be respectful and constructive. This is a hobby project built in the open.
