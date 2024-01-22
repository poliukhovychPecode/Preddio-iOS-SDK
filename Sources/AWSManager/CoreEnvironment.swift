import Foundation
import AWSIoT

enum Environment {
    case test
    case development
    case production
}

public struct AWSConfig {
    var awsRegion: AWSRegionType
    var ioTEndpoint: String
    var identityPoolID: String
    var awsIoTDataManagerKey: String
    var poolID: String
    var clientID: String
    var userPoolKey: String
}
