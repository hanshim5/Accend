# mobile_interface

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## lib/src structure

This folder holds the real app code (screens, widgets, and app setup).

### How to place files

- **`app/`**: global setup (root `MaterialApp`, routes, theme, constants)
- **`features/`**: one folder per big app area (login, onboarding, courses, etc.)
  - **`pages/`**: full screens
  - **`widgets/`**: smaller UI pieces used by those screens
  - **`controllers/`**: simple state/logic for that feature
- **`common/`**: shared widgets/helpers/services used by multiple features

We intentionally keep this simple for beginners.

### Front end Structure
```
lib/
  main.dart

  src/
    app/
      app.dart           // MyApp: MaterialApp, theme, initial route
      routes.dart        // route names & route table
      theme.dart         // colors, typography, spacing
      constants.dart     // strings, asset paths, etc.

    features/
      login/
        pages/
          login_page.dart
          forgot_password_page.dart
        widgets/
          login_form.dart
          social_login_buttons.dart
        controllers/
          login_controller.dart

      onboarding/
        pages/
          onboarding_intro_page.dart
          onboarding_goals_page.dart
          onboarding_language_level_page.dart
        widgets/
          onboarding_step_indicator.dart
        controllers/
          onboarding_controller.dart

      courses/
        pages/
          courses_list_page.dart
          course_detail_page.dart
          lesson_page.dart
        widgets/
          course_card.dart
          lesson_progress_bar.dart
        controllers/
          courses_controller.dart

      solo_practice/
        pages/
          solo_practice_home_page.dart
          exercise_detail_page.dart
          pronunciation_practice_page.dart
        widgets/
          exercise_card.dart
          timer_widget.dart
        controllers/
          solo_practice_controller.dart

      social/
        pages/
          feed_page.dart
          post_detail_page.dart
          notifications_page.dart
        widgets/
          post_card.dart
          comment_input.dart
        controllers/
          social_controller.dart

      public_profile/
        pages/
          public_profile_page.dart
          edit_profile_page.dart
        widgets/
          avatar_with_badges.dart
          stat_row.dart
        controllers/
          public_profile_controller.dart

      group_session/
        pages/
          group_session_list_page.dart
          group_session_detail_page.dart
          group_session_live_page.dart
        widgets/
          participant_avatar.dart
          live_waveform.dart
        controllers/
          group_session_controller.dart

    common/
      widgets/
        primary_button.dart
        primary_text_field.dart
        app_scaffold.dart        // common Scaffold wrapper
        app_bottom_nav_bar.dart  // if you have tab bar
      utils/
        validators.dart
        formatters.dart
      services/
        api_client.dart
        auth_service.dart
        user_service.dart
```
