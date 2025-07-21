Feature: User Onboarding & Profile
  As a new student
  I want to register with my phone, exam type, and subject
  So I receive personalized quizzes

  Scenario: Successful signup
    Given the app is freshly installed
    When I open the app
    Then I see "Sign Up" and "Login" buttons 