# iOS decisions and assumptions

- Swift UIKit + MVVM was explicitly chosen by the user. Minimum iOS 16; use Xcode 16 or later with Swift 5 language mode.
- This branch starts from main and includes frontend changes only. The Node backend is reviewed independently in feat/catalogue-backend. A separate local backend checkout supports integration before that PR merges.
- URLSession and system UIKit avoid third-party dependency setup. A checked-in Xcode project can be opened directly; a Python 3 generator maintains project references, the shared scheme and Info.plists.
- Views own layout/navigation, view models own main-actor screen state and validation, and CatalogueServing isolates the API implementation for tests.
- All product metadata comes from the backend. Only image URLs returned by the backend are loaded directly. No Fake Store product endpoints are called by the app.
- Featured selection and category grouping are controlled by the backend. Search runs when the keyboard Search button is pressed. Numeric prices do not invent a currency missing from the backend contract.
- Enquiry success is shown only after backend confirmation. Inputs remain available on failure; duplicate taps are prevented on the current form. Durable delivery and cross-request idempotency remain backend follow-ups.
- Simulator development can use localhost on the same Mac. Physical devices need a reachable LAN address or HTTPS server. Debug local-network allowances are separate from Release; Release requires a configured HTTPS backend.

## Validation and remaining work

Swift syntax, Xcode project references, scheme XML, Info.plists and repeatable project generation were checked in Linux. This does not establish UIKit compilation or runtime correctness. The 14 XCTest methods and simulator UI walkthrough still require macOS/CI. The dedicated iOS workflow is included; inspect its result in the PR.

Before submission, build/run in Xcode, test home/category/search/detail/enquiry against the backend, inspect the actual message in Mailpit, and check keyboard behavior, dark mode, larger text and VoiceOver. Before distribution, configure signing, bundle ID, app icon and the real HTTPS backend.
