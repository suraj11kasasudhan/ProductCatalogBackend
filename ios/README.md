# Product Catalogue — UIKit + MVVM

An iPhone/iPad client for the Node backend in the separate backend PR (`feat/catalogue-backend`). This frontend branch is based directly on `main` and intentionally contains no Node implementation. Minimum iOS 16; use Xcode 16 or later on macOS. UIKit screens are built programmatically, with no storyboards or third-party iOS dependencies.

## Run on your Mac

1. Extract the complete repository ZIP and open `ios/ProductCatalogue.xcodeproj` in Xcode 16 or later.
2. Select the **ProductCatalogue** scheme, choose an available iPhone simulator, and press Run.
3. Browse, search, and open product details. Both Debug and Release default to `https://productcatalogbackend-1.onrender.com/api`; no local backend or API key is needed.

If you previously set `CATALOGUE_API_BASE_URL` in Scheme → Run → Arguments → Environment Variables, remove it or update it to the hosted address. Debug environment overrides take precedence over the project's default. Stop and run the app again after changing the scheme.

The free hosted service may need around a minute to wake after inactivity. API requests allow 75 seconds, with a 90-second resource limit. Image requests remain separate. If the first load fails, tap Try again. Product data comes through the backend, now backed by DummyJSON.

Enquiries require real email-provider configuration on the backend. Browsing working does not establish that email delivery is configured.

### Optional local backend

To develop the backend locally, use a separate checkout of `feat/catalogue-backend`, run `docker compose up --build` on the same Mac, and set the Debug scheme's `CATALOGUE_API_BASE_URL` to `http://localhost:3000/api`. Docker's Mailpit inbox is available on port 8025 for local enquiry testing.

## Do I need to deploy the backend?

The hosted backend is configured by default. If you choose local development:

| Client                                         | Backend address / requirement                                            |
| ---------------------------------------------- | ------------------------------------------------------------------------ |
| Simulator on the backend's Mac                 | `http://localhost:3000/api`                                              |
| Physical iPhone on the same Wi-Fi              | Your Mac's reachable LAN address, such as `http://192.168.1.20:3000/api` |
| Testers outside your network or a released app | A reachable HTTPS backend; hosting is the usual choice                   |

For a physical device, run `npm ci && npm run dev` from the backend checkout and start Mailpit with `docker compose up -d mailpit`. The Node server binds to all interfaces. The default Compose configuration deliberately publishes only to loopback, so use the native Node process for this LAN workflow. Allow port 3000 through your Mac firewall only on a trusted development network. Select your signing team for a physical-device build, and allow the iOS local-network prompt.

To change the **Debug** API address, use Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables and add `CATALOGUE_API_BASE_URL` with the full address including `/api`. Alternatively, set the target's `CATALOGUE_API_BASE_URL` build setting. Do not add a real secret: there are no client API keys.

Debug Info.plist allows local networking and localhost HTTP only; it does not enable arbitrary insecure Internet requests. HTTP addresses on an unfamiliar network can still be subject to iOS ATS policy. Use HTTPS for a shared test server. Release Info.plist has no HTTP exceptions and ignores environment overrides. Both configurations use the hosted HTTPS backend; Release validation still rejects insecure URLs and `.invalid` placeholders.

Native URLSession requests are not governed by browser CORS rules; no CORS wildcard is needed for this app.

## Features and architecture

- **Browse:** home loads the five backend-curated products and available categories.
- **Category:** shows separate Featured and More products sections; empty groups are omitted.
- **Search:** submits title/description search when the keyboard Search button is tapped; handles no results and network errors.
- **Details:** fetches complete product details by ID and displays its image, rating, category, numeric price and description.
- **Enquiry:** name, email, optional phone and message; local validation for convenience, backend validation remains authoritative. Sending disables duplicate taps. Success appears only after the backend confirms SMTP acceptance. Failure keeps the form available for retry.
- Uses system colors, Dynamic Type, accessible field labels, image placeholders, cancellable loading, and keyboard-aware form scrolling.

```text
App/          lifecycle, dependency composition, and screen navigation factory
Models/       backend product DTO, catalogue groups, enquiry payload
Networking/   configuration, endpoint definitions, request building, and NetworkManager
Services/     CatalogueServing contract and CatalogueAPI response mapping
ViewModels/   screen state, loading, validation, and enquiry submission
Views/        screen views own layout and rendering; controllers bind state and emit events
```

View models run on the main actor and depend on `CatalogueServing`, not UIKit or a concrete network implementation. Controllers own their view model and loading task; update callbacks capture controllers weakly. Responses from cancelled or superseded loads cannot replace the current screen state. Controllers emit navigation events; CatalogueScreenFactory constructs destinations and injects their view models. CatalogueAPI depends on NetworkManaging, so transport can be replaced independently of the catalogue service.

The app gets **all product metadata from the backend**. Product images are downloaded from the image URLs returned by that backend and cached in memory. No DummyJSON product endpoints are called by the app.

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

There are **21 XCTest methods** covering view-model states, search normalization, invalid forms, enquiry success/failure/retry, duplicate prevention, URL/query encoding, backend DTO decoding, HTTP errors and POST payloads. API tests inject URLProtocol responses and require neither external product APIs nor SMTP. The shared scheme disables parallel test execution because its protocol stub has one shared response handler.

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

## Grid UI and smaller controllers

Browse uses a compositional collection layout: horizontal category chips, a two-column product grid on phones, three columns at widths of 700 points or more, and a single column at accessibility text sizes. All titles wrap. The warm neutral palette and accent adapt to dark mode. Details use a large image panel and a fixed enquiry action; the enquiry form remains keyboard-aware.

`CatalogueView`, `ProductDetailView`, and `EnquiryView` own UIKit layout and rendering. Controllers bind view-model updates, own cancellable tasks, and forward navigation events to `CatalogueScreenFactory`. `CatalogueStyle` contains shared colors and controls. View models own loading, validation and submission state; `NetworkManager` owns transport and decoding, with error translation centralized in `APIError`. No UI framework or networking dependencies were added.

Regression tests cover form state after retry and transport cancellation. The existing stale-search, enquiry duplication, endpoint encoding and backend error tests remain. Syntax parsing and project validation do not establish successful compilation or visual correctness; run Command-U and review narrow screens, rotation, accessibility text sizes, dark mode, keyboard scrolling, navigation and the live catalogue in Xcode.
