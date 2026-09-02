# OSA Management — Cloud Build

This project is prepared for Codemagic Android CI/CD.

The build workflow creates the Android platform files in CI, installs dependencies, runs `flutter analyze` and `flutter test`, then builds a release APK.

## Codemagic

1. Put this repository on GitHub.
2. In Codemagic, add the GitHub repository as a Flutter application.
3. Select the `android-release` workflow from `codemagic.yaml`.
4. Start the build.
5. Download the generated APK from the build artifacts.

The project does not require Flutter to be installed on the developer's Windows 7 machine for this cloud build.
