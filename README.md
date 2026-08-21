# personaclick_sdk

[![pub package](https://img.shields.io/pub/v/personaclick_sdk.svg)](https://pub.dev/packages/personaclick_sdk)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Flutter plugin for the PersonaClick personalization platform — a thin bridge over
the native [Android](https://github.com/personaclick/android-sdk) and
[iOS](https://github.com/personaclick/ios-sdk) SDKs. Storage, sessions, identity
and push delivery happen natively; Dart only routes calls to the right shop instance.

## Add the package

```bash
flutter pub add personaclick_sdk
```

Everything is exported from a single import:

```dart
import 'package:personaclick_sdk/personaclick_sdk.dart';
```

The native dependencies come with it — `com.github.personaclick:android-sdk` from
JitPack and the native pod from CocoaPods.

### Android

The plugin brings its own Gradle settings; the only value your app must agree on
is **`minSdk 24`**. Current Flutter versions already default to it, so a freshly
generated project needs no changes — set it only if you hardcoded something lower:

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}
```

Your app's Java version does **not** have to match the plugin's — `compileOptions`
and `jvmTarget` only govern the module they are declared in.

If your `android/settings.gradle.kts` centralizes repositories
(`RepositoriesMode.FAIL_ON_PROJECT_REPOS` / `PREFER_SETTINGS`), add JitPack there —
otherwise the native SDK cannot be resolved:

```kotlin
maven(url = "https://jitpack.io")
```

### iOS

Nothing to add: the plugin's podspec declares the native dependency and the
iOS 13.0 minimum itself, `pod install` runs as part of `flutter run`, and the
plugin registers its own application delegate — your `AppDelegate` stays untouched.

## Initialize

Initialize once, as early as possible — typically in `main()`, before `runApp`:

```dart
import 'package:flutter/widgets.dart';
import 'package:personaclick_sdk/personaclick_sdk.dart';

late final PersonalizationSdk sdk;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  sdk = Personaclick.initialize(
    const PersonaclickConfig(shopId: 'YOUR_SHOP_ID'),
  );

  runApp(const MyApp());
}
```

`Personaclick` is the entry point. `Personaclick.initialize` **returns the handle
synchronously** and starts native initialization in the background; calls issued
right after are queued natively until the session is ready, so the handle is
usable straight away. A broken setup surfaces as a `PlatformException` on the
first call you make with it (`bad_args` for an empty `shopId`, `init_failed` if
native init threw).

`shopId` is the only required field:

| Field | Default | Notes |
|---|---|---|
| `shopId` | — (**required**) | Your PersonaClick shop key |
| `apiDomain` | `api.personaclick.com` | API host |
| `stream` | `android` / `ios` | Traffic stream label; defaults to the current platform |
| `autoSendPushToken` | `true` | Fetches and sends the push token during init |
| `needReInitialization` | `false` | Forces a fresh session / device id |

Push delivery needs platform setup of its own — a Firebase config on Android, the
Push Notifications capability on iOS. Without it initialization still succeeds;
there is simply no token to send.

Keep one place that owns the handle, so no widget re-initializes:

```dart
class PersonaclickService {
  static const _shopId = 'YOUR_SHOP_ID';

  static PersonalizationSdk get sdk => Personaclick.isInitialized(_shopId)
      ? Personaclick.getInstance(_shopId)
      : Personaclick.initialize(const PersonaclickConfig(shopId: _shopId));
}
```

### Check that it worked

```dart
final sid = await sdk.getSid();   // session id
final did = await sdk.getDid();   // device id issued by PersonaClick
```

A non-empty `did` means the native SDK completed its handshake with the API.

### Several shops in one app

One app can run several shops at once — regional storefronts, super-app tenants.
Each gets its own native instance with isolated storage, session and `did`.

```dart
// Registered now, initialized on first use.
Personaclick.registerShops(const [
  PersonaclickConfig(shopId: 'shop-a'),
  PersonaclickConfig(shopId: 'shop-b'),
]);                                 // pass eagerInit: true to initialize up front

final shopA = Personaclick.getInstance('shop-a');
```

Address instances explicitly once more than one is registered: `getInstance()`
without an id resolves only while exactly one shop is registered, and throws
`AmbiguousShopException` otherwise (`UnknownShopIdException` for an id that was
never registered).

## Example app

A full demo — tracking, search, catalog, loyalty, push and two shops side by
side — lives in [`example/`](example):

```bash
cd example
flutter run
```

## Links

- [PersonaClick API reference](https://reference.api.personaclick.com/)
- [Issue tracker](https://github.com/personaclick/flutter-sdk/issues)

## License

MIT — see [LICENSE](LICENSE).
