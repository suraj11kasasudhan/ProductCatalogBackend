# iOS client plan

1. Keep the client on feature/ios-product-catalogue based directly on main, independent of the backend PR.
2. Implement UIKit home/category/search/detail/enquiry screens with MVVM and a testable URLSession API boundary.
3. Use the existing backend API envelopes and configurable /api base URL; keep success/error/retry behavior truthful.
4. Include a checked-in Xcode project, local setup instructions and 14 XCTest methods.
5. Perform Linux syntax/project checks, then require macOS/CI compilation, XCTest and manual simulator-to-backend validation.

The frontend can be merged before or after the backend because the changes use separate paths. Until the backend is merged, run it from its own checkout as described in README.md.
