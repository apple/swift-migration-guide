import ObjCLibrary
import Library
import XCTest

final class LibraryXCTests: XCTestCase {
    func testNonIsolated() throws {
        let color = ColorComponents()

        XCTAssertEqual(color.red, 1.0)
    }

    @MainActor
    func testIsolated() throws {
        let color = GlobalActorIsolatedColorComponents()

        XCTAssertEqual(color.red, 1.0)
    }

    func testNonIsolatedWithGlobalActorIsolatedType() async throws {
        let color = await GlobalActorIsolatedColorComponents()
        let redComponent = await color.red

        XCTAssertEqual(redComponent, 1.0)
    }
}

extension LibraryXCTests {
    func testCallbackOperation() async {
        let exp = expectation(description: "config callback")

        JPKJetPack.jetPackConfiguration {
            exp.fulfill()
        }

        await fulfillment(of: [exp])
    }
}
