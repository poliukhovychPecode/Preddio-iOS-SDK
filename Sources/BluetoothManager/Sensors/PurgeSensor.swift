import Foundation
import CoreBluetooth

final public class PurgeSensor: SensorBasicDetails, PurgeProtocol {
    public var type: PurgeSensorType

    init?(peripheral: CBPeripheral, rssi: NSNumber, hexs: [String],
          sensorType: SensorType, type: PurgeSensorType, dataBytes: Data?) {
        self.type = type
        super.init(peripheral: peripheral, rssi: rssi, hexs: hexs, sensorType: sensorType, dataBytes: dataBytes)
    }
    
    public var oxygenPercentage: Double? {
        guard sensorData[11] != "FF" && sensorData[10] != "FF",
              let oxygenLevel = Int((sensorData[11] + sensorData[10]), radix: 16) else {
            return nil
        }
        let oxygenLevelPercentage = Double(oxygenLevel) / 128.0
        return oxygenLevelPercentage
    }
    
    public  var oxygenConcentration: Double? {
        guard let patm = patm else {
            return nil
        }
        var concentration = patm * 40.0

        if concentration > 8000 {
            concentration = 8000.0
        } else if concentration < 0 {
            concentration = 0.0
        }
        return concentration
    }
    
    public var patm: Double? {
        guard sensorData[13] != "FF" && sensorData[12] != "FF",
              let patmValue = Int((sensorData[13] + sensorData[12]), radix: 16) else {
            return nil
        }
        let patmValueFloat = Double(patmValue) / 128.0
        return patmValueFloat
    }
    
    public var ppm: Double? {
        if let oxygenPercentage = oxygenPercentage {
            let result = (oxygenPercentage / 100.0) * 1_000_000
            return result
        } else {
            return nil
        }
    }
        
    public var durationOfPurge: String {
        guard sensorData[15] != "FF" && sensorData[14] != "FF",
              let duration = Int((sensorData[15] + sensorData[14]), radix: 16) else {
            return "NA"
        }
        let hours = Int(duration/60)
        let minutes = Int(duration%60)
        let hrsUnit = hours > 1 ? TranslationsKey.kHours.localized : TranslationsKey.kHour.localized
        let minUnit = minutes > 1 ? TranslationsKey.kMinutes.localized : TranslationsKey.kMinute.localized
        var finalValue = ""
        if hours > 0 {
            finalValue = "\(hours) \(hrsUnit)"
            finalValue += minutes > 0 ? " " : ""
        }
        
        if minutes > 0 {
            finalValue += "\(minutes) \(minUnit)"
        }
        
        if finalValue.isEmpty {
            return "0 \(TranslationsKey.kMinute.localized)"
        }
        
        return finalValue
    }
    
    public var calibrating: Bool {
        guard let dataBytes = dataBytes else {
            return false
        }
        
        let value = UInt8(dataBytes[9]).binaryDescription.dropFirst(2).dropLast(3)
        
        return value == "011"
    }
    
    public var statusState: Int? {
        guard sensorData[9] != "FF",
              let statusStateValue = UInt8((sensorData[9]), radix: 16) else {
            return nil
        }
        let intValue = Int(statusStateValue)
        return intValue
    }

}
