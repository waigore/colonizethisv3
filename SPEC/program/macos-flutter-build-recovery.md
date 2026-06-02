# macOS Flutter build recovery

**SPEC/program** — Local-environment recovery for intermittent macOS Flutter build failures caused by stale Swift incremental-build metadata. Not gameplay or simulation behavior.

---

## Symptom

`flutter run -d macos` or `flutter build macos` intermittently fails while compiling CocoaPods plugins, with output that includes any of:

- `SwiftDriver.ModuleDependencyGraph.ReadError error 14`
- `Could not read priors, will not do cross-module incremental builds`
- references to `*-primary.priors` under `app/build/macos/Build/Intermediates.noindex/...`

Root cause is stale or corrupted local incremental Swift metadata, not application code.

## Recovery sequence

Run from the repository root:

```bash
flutter clean
rm -rf app/build/macos
rm -rf ~/Library/Developer/Xcode/DerivedData/*Runner*
flutter pub get
cd app/macos
pod deintegrate
pod install
cd ..
flutter run -d macos
```

## Notes

- Keep `flutter pub get` **before** `pod install`: `flutter clean` removes `Flutter-Generated.xcconfig`, and CocoaPods requires it.
- If the local checkout uses a non-default app target name, adjust the `DerivedData` glob (`*Runner*`) accordingly.
- This is the single recommended recovery path for intermittent `SwiftDriver.ModuleDependencyGraph.ReadError` in local macOS builds.

## Acceptance criteria

- Given a local macOS checkout where `flutter run -d macos` failed with one of the listed Swift priors symptoms, when the maintainer runs the documented recovery sequence in order from the repository root, then `flutter run -d macos` completes the build without the `SwiftDriver.ModuleDependencyGraph.ReadError` failure on the same checkout.
- Given the recovery sequence, when a maintainer skips `flutter pub get` before `pod install`, then `pod install` fails because `Flutter-Generated.xcconfig` is absent and the recovery is treated as not followed.
