import Foundation
import CoreBluetooth

public enum Signal: Int {
    case no
    case low
    case good
    case veryGood
    case excellent
    
    public func icon() -> String {
        switch self {
        case .no :
            return "no"
        case .low :
            return "low"
        case .good :
            return "good"
        case .veryGood :
            return "verygood"
        case .excellent :
            return "excellent"
        }
    }
}

public enum SensorType: String {
    
    case Purge = "18"
    case Chill = "1A"
    case DO = "1C"
    
    public func hexValue() -> String {
        return String(format: "0x%@", self.rawValue)
    }
    
    internal func hexArrayLength() -> Int? {
        switch self {
        case .Purge : return 16
        case .Chill: return 12
        case .DO: return 16
        }
    }
    
    public func serialNumberRange() -> (Int,Int)? {
        return (3,8)
    }
    
    public static func creatObject(peripheral: CBPeripheral,
                                   rssi: NSNumber,
                                   hexs: [String],
                                   dataBytes: Data?) -> SensorBaseProtocol? {
        if  hexs.count > 2 && hexs[0] == "E0" && hexs[1] == "09" {
            
            switch SensorType(rawValue: hexs[2]) {
                
            case .Purge : return PurgeSensor(peripheral: peripheral,
                                             rssi: rssi,
                                             hexs: hexs,
                                             sensorType: .Purge,
                                             type: .purge,
                                             dataBytes: dataBytes)
            case .Chill: return ChillerSensor(peripheral: peripheral,
                                              rssi: rssi,
                                              hexs: hexs,
                                              sensorType: .Chill,
                                              type: .incoming)
            case .DO: return DOSensor(peripheral: peripheral,
                                      rssi: rssi,
                                      hexs: hexs,
                                      sensorType: .DO,
                                      dataBytes: dataBytes)
            default : return nil
            }
        }
        return nil
    }
    
}
