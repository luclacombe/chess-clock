# Contributing

Thanks for your interest in Chess Clock! Issues and pull requests are welcome.

## Getting Started

1. Fork the repo and clone it locally
2. Open `ChessClock/ChessClock.xcodeproj` in Xcode 15+
3. Build (Cmd+B) and run (Cmd+R)

## Running Tests

```bash
xcodebuild test -project ChessClock/ChessClock.xcodeproj \
  -scheme ChessClock -destination 'platform=macOS'
```

## Pull Requests

- Keep PRs focused on a single change
- Ensure all tests pass before submitting
- Run SwiftLint (`swiftlint lint --strict`) and fix any violations
- Follow the existing code style and conventions

## Reporting Bugs

Open an issue with:
- macOS version
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots if applicable
