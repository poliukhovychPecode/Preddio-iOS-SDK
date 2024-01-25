import Foundation
import CoreBluetooth
import UIKit

open class SensorBasicDetails : SensorBaseProtocol {
    
    public let sensorData: [String]
    public let peripheral: CBPeripheral
    public let rssiInput: NSNumber
    public var timeStamp: Date
    public let sensorType: SensorType
    public var dataBytes: Data?
    
    public init?(peripheral: CBPeripheral,
          rssi: NSNumber,
          hexs: [String],
          timeStamp: Date = Date(),
          sensorType: SensorType,
          dataBytes: Data? = nil) {
        if hexs.count > 2 && SensorType(rawValue: hexs[2])?.hexArrayLength() == hexs.count {
            self.sensorData = hexs
            self.peripheral = peripheral
            self.rssiInput = rssi
            self.timeStamp = timeStamp
            self.sensorType = sensorType
            self.dataBytes = dataBytes
        } else {
            return nil
        }
    }
    
    public var mfgId: String {
        if (sensorData[0] == "E0" && sensorData[1] == "09") ||
            sensorData[0] == "09" && sensorData[1] == "E0" {
            return "0x09E0"
        }
        return ""
    }
    
    public var productType: String {
        return sensorData[2]
    }
    
    public var serialNumber: String {
        if let (startIndex, endIndex) = SensorType(rawValue: productType)?.serialNumberRange() {
            let serial = sensorData[startIndex...endIndex].reversed().joined(separator: "")
            return serial
        }
        return ""
    }
    
    public var connectedState: CBPeripheralState {
        get {
            peripheral.state
        }
        set {
            
        }
    }
    
    public var statusBitmap: String {
        return ""
    }
    
    public var deviceName: String {
        return peripheral.name ?? ""
    }
    
    public var signalStrength: Signal {
        let diffTime = Date().timeIntervalSince(timeStamp)
        if diffTime > 30 {
            return .no
        }
        let signal = rssiInput.doubleValue
        if signal <= -85 {
            return Signal.low
        } else if signal <= -70 {
            return Signal.good
        } else if signal <= -55 {
            return Signal.veryGood
        }
        return Signal.excellent
        
    }
    
    public var signalStrengthDescription: String {
        let signal = rssiInput.intValue
        return "\(signal) dBm"
    }
    
    public var signalStrengthColor: UIColor? {
//        let signal = rssiInput.intValue
//        if signal <= -91 {
//            return .ptRed
//        } else if signal <= -71 {
//            return .ptYellow
//        } else {
//            return .ptGreen
//        }
        return nil
    }
}
