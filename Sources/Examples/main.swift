import Dispatch

/// A Serial queue uses for manual synchronization
let manualSerialQueue = DispatchQueue(label: "com.apple.SwiftMigrationGuide")

// Note: top-level code provides an asynchronous MainActor-isolated context
await exerciseGlobalExamples()
