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
