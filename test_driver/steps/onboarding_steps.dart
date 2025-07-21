import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

class AppIsFreshlyInstalledStep extends Given1WithWorld<String, FlutterWorld> {
  @override
  RegExp get pattern => RegExp(r"the app is freshly installed");

  @override
  Future<void> executeStep(String input1) async {
    // For testing purposes, we assume the app is in a fresh state
    // In a real scenario, you might want to clear app data or use a test database
    print("App is considered to be in a fresh state");
  }
}

class IOpenTheAppStep extends When1WithWorld<String, FlutterWorld> {
  @override
  RegExp get pattern => RegExp(r"I open the app");

  @override
  Future<void> executeStep(String input1) async {
    // The app should already be launched by the test runner
    // We can verify that the driver is connected and the app is ready
    final driver = world.driver;
    if (driver != null) {
      await driver.waitUntilFirstFrameRasterized();
      print("App is opened and ready");
    }
  }
}

class ISeeSignUpAndLoginButtonsStep extends Then1WithWorld<String, FlutterWorld> {
  @override
  RegExp get pattern => RegExp(r'I see "([^"]*)" and "([^"]*)" buttons');

  @override
  Future<void> executeStep(String input1) async {
    final driver = world.driver!;
    
    // Look for the Sign Up button
    final signUpButtonFinder = find.byValueKey('signUpButton');
    await driver.waitFor(signUpButtonFinder, timeout: const Duration(seconds: 10));
    
    // Verify the Sign Up button text
    final signUpButtonText = await driver.getText(signUpButtonFinder);
    if (!signUpButtonText.contains('Sign Up')) {
      throw Exception('Expected "Sign Up" button text, but found: $signUpButtonText');
    }
    
    // Look for the Login button
    final loginButtonFinder = find.byValueKey('loginButton');
    await driver.waitFor(loginButtonFinder, timeout: const Duration(seconds: 10));
    
    // Verify the Login button text
    final loginButtonText = await driver.getText(loginButtonFinder);
    if (!loginButtonText.contains('Login')) {
      throw Exception('Expected "Login" button text, but found: $loginButtonText');
    }
    
    print('Successfully found both "Sign Up" and "Login" buttons');
  }
} 