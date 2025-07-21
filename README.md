# Exam Coach App

A Flutter application for exam coaching with personalized quizzes.

## Features

- **User Onboarding**: Clean and intuitive onboarding screen with Sign Up and Login options
- **Gherkin BDD Testing**: Comprehensive behavior-driven development tests using flutter_gherkin

## Project Structure

```
examCoachApp/
├── lib/
│   ├── main.dart                           # Main app entry point
│   └── screens/
│       └── onboarding_screen.dart          # Onboarding screen with Sign Up/Login buttons
├── test_driver/
│   ├── app.dart                            # Test app entry point
│   ├── app_test.dart                       # Main test runner
│   ├── features/
│   │   └── user_onboarding.feature         # Gherkin feature file
│   └── steps/
│       └── onboarding_steps.dart           # Step definitions
├── pubspec.yaml                            # Dependencies and project configuration
└── README.md                               # This file
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

1. Clone the repository or create the project in your desired directory
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

To run the app in development mode:

```bash
flutter run
```

The app will launch with the `OnboardingScreen` as the initial route, displaying:
- "Sign Up" button (elevated button with purple background)
- "Login" button (outlined button with purple border)

## Testing

### Gherkin BDD Tests

This project includes Behavior-Driven Development (BDD) tests using `flutter_gherkin`.

#### Running Gherkin Tests

1. Start the app in test mode:
   ```bash
   flutter drive --target=test_driver/app.dart
   ```

2. In another terminal, run the Gherkin tests:
   ```bash
   flutter drive --target=test_driver/app_test.dart
   ```

#### Test Scenarios

The current test suite covers:

**Feature: User Onboarding & Profile**
- **Scenario**: Successful signup
  - Given the app is freshly installed
  - When I open the app
  - Then I see "Sign Up" and "Login" buttons

#### Test Reports

Test results are generated in multiple formats:
- Console output with progress and summary
- JSON report (`report.json`) for CI/CD integration

### Step Definitions

The following step definitions are implemented:

1. **AppIsFreshlyInstalledStep**: Validates fresh app state
2. **IOpenTheAppStep**: Ensures app is launched and ready
3. **ISeeSignUpAndLoginButtonsStep**: Verifies both buttons are present and correctly labeled

## Development

### Adding New Features

1. Create new screens in `lib/screens/`
2. Add corresponding Gherkin feature files in `test_driver/features/`
3. Implement step definitions in `test_driver/steps/`
4. Update the test runner in `test_driver/app_test.dart`

### Widget Keys

Important widget keys used for testing:
- `signUpButton`: Key for the Sign Up button
- `loginButton`: Key for the Login button

## Dependencies

### Main Dependencies
- `flutter`: Flutter SDK
- `cupertino_icons`: iOS-style icons

### Dev Dependencies
- `flutter_gherkin`: BDD testing framework
- `flutter_driver`: UI automation and testing
- `flutter_test`: Flutter testing framework
- `flutter_lints`: Dart code linting

## Architecture

The app follows a simple, clean architecture:
- **Screens**: Individual UI screens (currently `OnboardingScreen`)
- **Main App**: Entry point with routing configuration
- **Testing**: Comprehensive BDD test suite with step definitions

## Future Enhancements

- User registration and authentication
- Exam type and subject selection
- Personalized quiz generation
- User profile management
- Progress tracking

## Contributing

1. Follow Flutter/Dart style guidelines
2. Add Gherkin tests for new features
3. Ensure all tests pass before submitting changes
4. Update documentation as needed 