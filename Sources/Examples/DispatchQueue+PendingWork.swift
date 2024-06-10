import Dispatch

extension DispatchQueue {
    /// Returns once any pending work has been completed.
    func pendingWorkComplete() async {
        // TODO: update to withCheckedContinuation https://github.com/apple/swift/issues/74206
        await withUnsafeContinuation { continuation in
            self.async(flags: .barrier) {
                continuation.resume()
            }
        }
    }
}
