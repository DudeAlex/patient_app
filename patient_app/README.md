## Patient App (Flutter)

Local-first personal records app with optional Google Drive appData backup.

What’s included
- Flutter scaffold with basic app shell
- Planned dependencies for Isar, security, and Google APIs (pub get not run)
- Core stubs: DB open helper, crypto helper, Google sign-in stub, Drive sync stub

Next steps
1. Configure Google Cloud OAuth for Android/iOS with Drive appData scope.
2. Run `flutter pub get` in `patient_app/`.
3. Add Isar entities and repositories, then run `dart run build_runner build`.
4. Implement backup/export and import/restore wiring.

