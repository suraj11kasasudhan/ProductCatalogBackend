# Product Catalogue for iOS

A UIKit + MVVM catalogue app with a blush pink theme, adaptive product cards, horizontal category browsing, search, product details, and product enquiries.

This branch contains the iOS client. The Node.js backend is maintained separately on [`feat/catalogue-backend`](https://github.com/suraj11kasasudhan/ProductCatalogBackend/tree/feat/catalogue-backend). The hosted backend uses DummyJSON and exposes the product contract consumed by the app.

## Run the app

Requires **Xcode 16+**, **macOS**, and an iOS 16+ simulator or device. No third-party iOS dependencies or project generation are required.

1. Open `ios/ProductCatalogue.xcodeproj`.
2. Select the **ProductCatalogue** scheme and an available iPhone simulator.
3. Press **Run**.

Both Debug and Release default to the live backend:

```text
https://productcatalogbackend-1.onrender.com/api
```

If an older scheme defines `CATALOGUE_API_BASE_URL`, remove it or update it to this address, then stop and run again. Render's free service can take around a minute to wake after inactivity; retry if the first request fails.

## App experience

- **Browse:** five curated products and horizontally scrolling categories.
- **Category:** separate Featured and More products groups.
- **Search:** submit a product name or description with the keyboard Search button.
- **Details:** product image, description, numeric price, rating, and an enquiry action.
- **Enquiry:** validated contact fields and message, duplicate-submission prevention, and retryable errors. Confirmation requires backend email acceptance.
- **Appearance:** baby pink backgrounds, rose accents, plum text, and a matching dark theme. The grid adapts to screen width and accessibility text sizes.

All product metadata comes through the backend. Product images use backend-provided URLs. No currency is invented when the backend supplies only a numeric price.

## Code structure

| Folder | Responsibility |
| --- | --- |
| `App` | App lifecycle, dependency wiring, and screen navigation |
| `Models` | Product responses, catalogue modes, and enquiry validation |
| `Networking` | API configuration, endpoints, requests, transport, and error mapping |
| `Services` | Catalogue service contract and response mapping |
| `ViewModels` | Screen state, async loading, and enquiry submission |
| `Views` | Screen layout, rendering, reusable components, and small binding controllers |

Controllers own cancellable tasks and forward navigation events. View models depend on protocols; superseded loads cannot overwrite newer results. Styling is centralized in `CatalogueStyle`.

## Tests and validation

Run **Command-U** in Xcode. The test target contains **21 XCTest methods** covering loading and retry states, stale search responses, enquiry validation and duplicate prevention, endpoint encoding, response decoding, cancellation, and HTTP errors. Stubbed API tests need neither an external product API nor SMTP.

Swift syntax, Xcode project references, scheme/plist structure, repeatable project generation, and selected text/button contrast pairs have been checked in the Linux workspace. These checks do not establish an Xcode build, XCTest pass, or complete visual/accessibility review. See the macOS checks on [the iOS PR](https://github.com/suraj11kasasudhan/ProductCatalogBackend/pull/2) for CI results.

The user has confirmed that the hosted catalogue returns product data. Production enquiry email still requires separate SMTP/provider configuration; browsing does not verify email delivery.

See [the iOS guide](ios/README.md) for local backend setup, API overrides, test commands, and the manual integration checklist.
