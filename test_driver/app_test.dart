import 'dart:async';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'steps/onboarding_steps.dart';

Future<void> main() {
  final config = FlutterTestConfiguration()
    ..features = [RegExp(r'test_driver/features/*.feature')]
    ..reporters = [
      ProgressReporter(),
      TestRunSummaryReporter(),
      JsonReporter(path: './report.json'),
    ]
    ..stepDefinitions = [
      AppIsFreshlyInstalledStep(),
      IOpenTheAppStep(),
      ISeeSignUpAndLoginButtonsStep(),
    ]
    ..customStepParameterDefinitions = []
    ..restartAppBetweenScenarios = true
    ..targetAppPath = "test_driver/app.dart"
    ..exitAfterTestRun = true;

  return GherkinRunner().execute(config);
} 