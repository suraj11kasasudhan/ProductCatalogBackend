# Product Catalogue — UIKit + MVVM

An iPhone/iPad client for the Node backend in the separate backend PR (`feat/catalogue-backend`). This frontend branch is based directly on `main` and intentionally contains no Node implementation. Minimum iOS 16; use Xcode 16 or later on macOS. UIKit screens are built programmatically, with no storyboards or third-party iOS dependencies.

## Run on your Mac

1. Until the backend PR is merged into `main`, use a separate checkout for the backend. From this frontend checkout's root:

   ```sh
   git clone --single-branch --branch feat/catalogue-backend https://github.com/suraj11kasasudhan/ProductCatalogBackend.git ../ProductCatalogBackend-service
   cd ../ProductCatalogBackend-service
   docker compose up --build
   ```

   If that sibling directory already exists, reuse it after checking it is the backend checkout. After the backend PR merges, a checkout of `main` can run the same backend commands instead. No worktree is required.

2. In another terminal, return to this frontend checkout and open the checked-in project:

   ```sh
   open ios/ProductCatalogue.xcodeproj
   ```

3. Select the **ProductCatalogue** scheme, choose an available iPhone simulator, and press Run. Debug builds default to `http://localhost:3000/api`. No signing account is needed for the simulator. Start Docker on the **same Mac**; a server in the Codex cloud workspace is not your Mac's localhost.

Open the local Mailpit inbox on port 8025 to inspect submitted enquiries. The local setup captures messages without delivering externally. If catalogue requests fail, check the backend terminal and verify `curl http://localhost:3000/api/products/featured` on your Mac. This requires Internet access from the backend to Fake Store API.

## Do I need to deploy the backend?

No deployment is needed for local simulator development. For other cases:

| Client                                         | Backend address / requirement                                            |
| ---------------------------------------------- | ------------------------------------------------------------------------ |
| Simulator on the backend's Mac                 | `http://localhost:3000/api`                                              |
| Physical iPhone on the same Wi-Fi              | Your Mac's reachable LAN address, such as `http://192.168.1.20:3000/api` |
| Testers outside your network or a released app | A reachable HTTPS backend; hosting is the usual choice                   |

For a physical device, run `npm ci && npm run dev` from the backend checkout and start Mailpit with `docker compose up -d mailpit`. The Node server binds to all interfaces. The default Compose configuration deliberately publishes only to loopback, so use the native Node process for this LAN workflow. Allow port 3000 through your Mac firewall only on a trusted development network. Select your signing team for a physical-device build, and allow the iOS local-network prompt.

To change the **Debug** API address, use Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables and add `CATALOGUE_API_BASE_URL` with the full address including `/api`. Alternatively, set the target's `CATALOGUE_API_BASE_URL` build setting. Do not add a real secret: there are no client API keys.

Debug Info.plist allows local networking and localhost HTTP only; it does not enable arbitrary insecure Internet requests. HTTP addresses on an unfamiliar network can still be subject to iOS ATS policy. Use HTTPS for a shared test server. Release Info.plist has no HTTP exceptions, ignores environment overrides, and deliberately uses an unusable `.invalid` placeholder until you set a real HTTPS URL in the Release build setting. Release configuration validation rejects that placeholder.

Native URLSession requests are not governed by browser CORS rules; no CORS wildcard is needed for this app.

## Features and architecture

- **Browse:** home loads the five backend-curated products and available categories.
- **Category:** shows separate Featured and More products sections; empty groups are omitted.
- **Search:** submits title/description search when the keyboard Search button is tapped; handles no results and network errors.
- **Details:** fetches complete product details by ID and displays its image, rating, category, numeric price and description.
- **Enquiry:** name, email, optional phone and message; local validation for convenience, backend validation remains authoritative. Sending disables duplicate taps. Success appears only after the backend confirms SMTP acceptance. Failure keeps the form available for retry.
- Uses system colors, Dynamic Type, accessible field labels, image placeholders, cancellable loading, and keyboard-aware form scrolling.

```text
App/          app and scene lifecycle; wires tabs and API dependency
Models/       backend product DTO, catalogue groups, enquiry payload
Networking/   API URL configuration, URLSession requests and HTTP errors
ViewModels/   screen state, loading, validation, and enquiry submission
Views/        UIKit layout, navigation, reusable cells/status/image views
```

View models run on the main actor and depend on `CatalogueServing`, not UIKit or a concrete network implementation. Controllers own their view model and loading task; update callbacks capture controllers weakly. Responses from cancelled loads cannot replace the current screen state.

The app gets **all product metadata from the backend**. Product images are downloaded from the image URLs returned by that backend and cached in memory. No Fake Store product endpoints are called by the app.

The backend does not supply currency information, so the UI labels the numeric price without inventing a currency. There are no account, checkout, or payment screens.

## Tests

In Xcode, press Command-U. Or select an installed simulator name from `xcrun simctl list devices available` and run:

```sh
xcodebuild test \
  -project ios/ProductCatalogue.xcodeproj \
  -scheme ProductCatalogue \
  -destination 'platform=iOS Simulator,name=YOUR_INSTALLED_IPHONE_SIMULATOR' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

There are **14 XCTest methods** covering view-model states, search normalization, invalid forms, enquiry success/failure/retry, duplicate prevention, URL/query encoding, backend DTO decoding, HTTP errors and POST payloads. API tests inject URLProtocol responses and require neither Fake Store access nor SMTP. The shared scheme disables parallel test execution because its protocol stub has one shared response handler.

The separate `.github/workflows/ios.yml` GitHub Actions workflow includes a macOS job that selects an available iPhone simulator and runs the same Xcode test target. Inspect the PR result before treating the app as build-verified.

**Validation limit:** this cloud machine is Linux and has no Swift compiler, Xcode or iOS simulator. Swift syntax and Xcode-project parsing were checked, but an iOS build, XCTest execution, visual review and simulator-to-backend interaction have not been run here. These remain required on macOS/CI.

## Manual integration checklist

1. Home shows five featured products; open a category and verify featured/additional groups.
2. Search for a known product, then an absent term; select a result and inspect details.
3. Submit a valid enquiry; verify confirmation in the app and the message in Mailpit.
4. Stop Mailpit and submit again: verify the app shows an error and retains form input. Restart Mailpit and retry.
5. Stop the backend: verify loading completes with an error and retry works after restart.
6. Review small-screen layout, keyboard scrolling, dark mode, larger text and VoiceOver in the simulator.

## Maintaining the Xcode project

The project, scheme and two Info.plists are checked in, so no project-generation tool is required to run the app. Their source of truth is the dependency-free Python generator:

```sh
python3 ios/generate_project.py
```

Run it after adding/removing Swift files or changing generated build settings. It overwrites the project, shared scheme and Info.plists; update the generator rather than manually editing those generated files.

Before public distribution, configure the actual bundle ID/signing team, HTTPS backend, app icon and privacy/distribution requirements. Durable enquiry delivery and request idempotency remain backend follow-ups rather than promises made by this client.
