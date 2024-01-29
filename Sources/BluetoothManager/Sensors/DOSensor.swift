import Foundation
import CoreBluetooth

final public class DOSensor: SensorBasicDetails, DOProtocol {
    public var type: DOSensorType = .doType
    
    public var oxygenConcentration: Double? {
        let isZero = sensorData[11] + sensorData[10] == "0000"
        guard sensorData[11] != "FF" && sensorData[10] != "FF", !isZero,
              let patmValue = UInt((sensorData[11] + sensorData[10]), radix: 16) else {
            return nil
        }
        let patmValueFloat = Double(patmValue)
        return patmValueFloat
    }
    
    public var temperature: Double? {
        let isZero = sensorData[13] + sensorData[12] == "0000"
        guard sensorData[13] != "FF" && sensorData[12] != "FF", !isZero,
              let temperatureValue = UInt16((sensorData[13] + sensorData[12]), radix: 16) else {
            return nil
        }
        let signedInt = Int16(bitPattern: temperatureValue)
        let result = Double(signedInt) / 128.0
        
        return result
    }
    
    public var duration: String {
        guard sensorData[15] != "FF" && sensorData[14] != "FF",
              let duration = UInt((sensorData[15] + sensorData[14]), radix: 16) else {
            return "NA"
        }
        let hours = Int(duration / 60)
        let minutes = Int(duration % 60)
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
    
    public var durationDouble: Double? {
        guard sensorData[15] != "FF" && sensorData[14] != "FF",
              let duration = UInt((sensorData[15] + sensorData[14]), radix: 16) else {
            return nil
        }
        
        return Double(duration)
    }
    
    public var statusState: Int? {
        guard let dataBytes = dataBytes else {
            return nil
        }
        
        let value = UInt8(dataBytes[9]).binaryDescription.dropFirst(2).dropLast(3)
        let result = Int(value)
        return result
    }
    
}
