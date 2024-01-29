import Foundation

extension Data {
    var uint32: UInt32 {
        withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}
