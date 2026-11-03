# iOS AI usage

The user requested a Swift UIKit + MVVM frontend integrated with the existing Node API, then asked for separate backend and frontend PRs into main.

OpenAI Codex (the GPT-6-based assistant available in the session; exact variant not exposed) generated the UIKit screens, URLSession client, dependency-injected view models, XCTest cases, project generator and documentation. No parallel agents were used. No agent instruction files or secrets were added.

Key directions were to use native UIKit/MVVM, preserve backend ownership of product data, show enquiry success only after the backend confirms sending, and make simulator development possible without deployment. The checked-in Xcode project avoids requiring XcodeGen on the reviewer's Mac.

Review corrected optional URL-scheme handling, made cancelled request results unable to replace current screen state, and avoided controller/task retain cycles. Preliminary checks used Swift syntax and Xcode-project parsers. These are not compilation or XCTest execution. The Linux workspace has no Xcode, Swift compiler or iOS simulator; macOS CI and manual integration remain required.

The original combined frontend commit was preserved on a local backup branch. A non-destructive revert removes it from the backend PR's final diff. This independent branch carries only the frontend and its own docs/workflow.

Human review and ownership remain required. The submitter should record actual planning, implementation, macOS testing and review time before submitting; do not treat assistant execution time as a human time log.
