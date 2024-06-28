import Library
import ObjCLibrary
import Testing

struct LibraryTest {
    @Test func testNonIsolated() throws {
        let color = ColorComponents()

        #expect(color.red == 1.0)
    }

    @MainActor
    @Test func testIsolated() throws {
        let color = GlobalActorIsolatedColorComponents()

        #expect(color.red == 1.0)
    }

    @Test func testNonIsolatedWithGlobalActorIsolatedType() async throws {
        let color = await GlobalActorIsolatedColorComponents()

        await #expect(color.red == 1.0)
    }
}

extension LibraryTest {
    @Test func testCallbackOperation() async {
        await confirmation() { completion in
            // function explicitly opts out of an generated async version
            // so it requires a continuation here
            await withCheckedContinuation { continuation in
                JPKJetPack.jetPackConfiguration {
                    completion()
                    continuation.resume()
                }
            }
        }
    }
}
