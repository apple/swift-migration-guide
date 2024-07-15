import Dispatch
import ObjCLibrary

/// Example that backs an actor with a queue.
///
/// > Note: `DispatchSerialQueue`'s initializer was only made available in more recent OS versions.
@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, *)
actor LandingSite {
    private let queue = DispatchSerialQueue(label: "SerialQueue")

	// this currently failed to build because of the @available usage, rdar://116684282
//    nonisolated var unownedExecutor: UnownedSerialExecutor {
//        queue.asUnownedSerialExecutor()
//    }

    func acceptTransport(_ transport: JPKJetPack) {
        // this function will be running on queue
    }
}

func exerciseIncrementalMigrationExamples() async {
    print("Incremental Migration Examples")

    if #available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, *) {
        print("  - using an actor with a DispatchSerialQueue executor")
        let site = LandingSite()

        let transport = JPKJetPack()

        await site.acceptTransport(transport)
        await site.acceptTransport(transport)
        await site.acceptTransport(transport)
    }
}
