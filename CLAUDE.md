# Budget Tracker Flutter App Guide

## Development Commands
- Run app: `flutter run`
- Run all tests: `flutter test`
- Run single test: `flutter test test/widget_test.dart`
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`
- Check pub packages: `flutter pub outdated`
- Update packages: `flutter pub upgrade`

## Code Style Guidelines
- **File Structure**: Group by functionality (models/, providers/, screens/, utils/, widgets/)
- **Imports**: Flutter/Dart libraries first, then external packages, then relative imports
- **Naming**: Classes use PascalCase, methods/variables use camelCase, files use snake_case
- **Widgets**: Prefer StatelessWidget when possible, extract reusable widgets
- **State Management**: Use Provider pattern for app-wide state
- **Constants**: Define theme constants and strings in dedicated files
- **Error Handling**: Use try/catch with specific exceptions and user-friendly error messages
- **Documentation**: Add doc comments for public APIs and complex logic
- **Testing**: Write widget tests for UI components and unit tests for business logic

Follow standard Flutter linting rules from flutter_lints package.