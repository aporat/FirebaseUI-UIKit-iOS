# FirebaseUI for iOS — UIKit Fork

This is a UIKit-only fork of [FirebaseUI for iOS](https://github.com/firebase/FirebaseUI-iOS). It keeps the Objective-C UIKit components (auth flows, Realtime Database, Firestore, and Storage bindings) and drops the SwiftUI packages, CocoaPods support, and the sample apps that shipped upstream.

FirebaseUI is an open-source library for iOS that allows you to quickly connect common UI elements to the [Firebase](https://firebase.google.com?utm_source=FirebaseUI-iOS) database for data storage, allowing views to be updated in realtime as they change, and providing simple interfaces for common tasks like displaying lists or collections of items.

Additionally, FirebaseUI simplifies Firebase authentication by providing easy to use auth methods that integrate with common identity providers like Facebook, Apple, and Google as well as allowing developers to use a built in headful UI for ease of development.

FirebaseUI clients are also available for [Android](https://github.com/firebase/FirebaseUI-Android) and [web](https://github.com/firebase/firebaseui-web).

## Requirements

- iOS 18.0 or later
- Xcode 16 or later (Swift tools version 6.0)
- Swift Package Manager. CocoaPods and Carthage are not supported by this fork.

## Installing FirebaseUI for iOS

Add the package to your project in Xcode with **File → Add Package Dependencies…** and enter the repository URL:

```
https://github.com/aporat/FirebaseUI-UIKit-iOS
```

Or add it to the `dependencies` of your own `Package.swift`:

```swift
.package(url: "https://github.com/aporat/FirebaseUI-UIKit-iOS", branch: "UIKit"),
```

Then add only the products you need to your target. Each product is an independent library:

| Product                   | What it provides                                   |
| ------------------------- | -------------------------------------------------- |
| `FirebaseAuthUI`          | Core auth picker, account settings, shared UI      |
| `FirebaseEmailAuthUI`     | Email / password and email-link sign-in            |
| `FirebasePhoneAuthUI`     | Phone number sign-in                               |
| `FirebaseGoogleAuthUI`    | Google Sign-In                                     |
| `FirebaseFacebookAuthUI`  | Facebook Login                                     |
| `FirebaseOAuthUI`         | Sign in with Apple, Twitter, GitHub, Microsoft, Yahoo, and other OAuth providers |
| `FirebaseAnonymousAuthUI` | Anonymous sign-in                                  |
| `FirebaseDatabaseUI`      | Realtime Database table and collection view bindings |
| `FirebaseFirestoreUI`     | Firestore table and collection view bindings       |
| `FirebaseStorageUI`       | Cloud Storage image loading via SDWebImage         |

The auth provider libraries all depend on `FirebaseAuthUI`, so adding one of them pulls the core library in automatically. In a `Package.swift` target they look like this:

```swift
.product(name: "FirebaseAuthUI", package: "FirebaseUI-UIKit-iOS"),
.product(name: "FirebaseEmailAuthUI", package: "FirebaseUI-UIKit-iOS"),
.product(name: "FirebaseGoogleAuthUI", package: "FirebaseUI-UIKit-iOS"),
```

You also need to [add the Firebase SDK](https://firebase.google.com/docs/ios/setup) to your project and call `FirebaseApp.configure()` before using any FirebaseUI component. The Firebase, Google Sign-In, Facebook, and SDWebImage SDKs are resolved as transitive dependencies of this package.

### Provider configuration

Some providers need extra project configuration:

- **Google Sign-In**: add a URL type to your target with the `REVERSED_CLIENT_ID` value from your `GoogleService-Info.plist`.
- **Facebook Login**: add a `fb{your-app-id}` URL type and the `FacebookAppID` key to your `Info.plist`, and enable the Keychain Sharing capability. See the [Facebook iOS SDK setup guide](https://developers.facebook.com/docs/ios/getting-started) for details.
- **Sign in with Apple**: enable the Sign in with Apple capability on your target.
- **Phone Auth**: enable the Push Notifications capability and the Remote notifications background mode, and upload your APNs key or certificate to the Firebase console so silent pushes can be used for app verification. See the [Firebase phone auth guide](https://firebase.google.com/docs/auth/ios/phone-auth).

## Documentation

The READMEs for components of FirebaseUI can be found in their respective
project folders.

- [Auth](FirebaseAuthUI/README.md)
- [PhoneAuth](FirebasePhoneAuthUI/README.md)
- [Database](FirebaseDatabaseUI/README.md)
- [Firestore](FirebaseFirestoreUI/README.md)
- [Storage](FirebaseStorageUI/README.md)

## Local Setup

Clone the repository and open the package directly in Xcode:

```bash
git clone https://github.com/aporat/FirebaseUI-UIKit-iOS.git
cd FirebaseUI-UIKit-iOS
open Package.swift
```

Xcode resolves the dependencies and exposes one scheme per product. To build a library from the command line:

```bash
xcodebuild -scheme FirebaseEmailAuthUI -destination 'generic/platform=iOS Simulator' build
```

## Differences from upstream

- SwiftUI packages, CocoaPods podspecs, Carthage support, and the sample apps have been removed.
- The minimum deployment target is iOS 18, and pre-iOS 13 availability checks have been dropped.
- `FUIEmailAuth` initializers are named `initWithAuthUI:signInMethod:…` instead of `initAuthAuthUI:…`.
- The email sign-in flow no longer calls the deprecated `fetchSignInMethodsForEmail:`, so it works with Firebase's Email Enumeration Protection enabled.
- Dependencies are tracked against current releases: Firebase 12, GoogleSignIn 10, and Facebook SDK 18.

## Contributing

This fork tracks the upstream repository loosely. Bug reports and pull requests are welcome; changes that apply to the shared Objective-C sources are best sent upstream to [firebase/FirebaseUI-iOS](https://github.com/firebase/FirebaseUI-iOS) as well.

## License

FirebaseUI is released under the Apache License 2.0. See [LICENSE](LICENSE).
