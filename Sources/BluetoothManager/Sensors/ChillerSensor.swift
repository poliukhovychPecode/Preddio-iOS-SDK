import Foundation
import CoreBluetooth

final public class ChillerSensor: SensorBasicDetails, ChillerProtocol {
    public var type: TemperatureSensorType

    init?(peripheral: CBPeripheral,
          rssi: NSNumber,
          hexs: [String],
          sensorType: SensorType,
          type: TemperatureSensorType) {
        self.type = type
        super.init(peripheral: peripheral, rssi: rssi, hexs: hexs, sensorType: sensorType)
    }
    
    public var temperature: Double? {
        guard sensorData[11] != "FF" && sensorData[10] != "FF",
              let temperatureValue = UInt16((sensorData[11] + sensorData[10]), radix: 16) else {
            return nil
        }
        let signedInt = Int16(bitPattern: temperatureValue)
        let result = Double(signedInt) / 128.0
        
        return result
    }
    
    public var strTemperature: String {
        guard let temperature = temperature else {
            return ""
        }
        return String(format: "%.02f", temperature)
    }
    
    public var temperatureInFahrenheit: Double? {
        guard let temperature = temperature else {
            return nil
        }
        return (temperature * (9/5)) + 32
    }
    
    public var statusState: Int? {
        guard sensorData[9] != "FF",
              let statusStateValue = Int((sensorData[9]), radix: 16) else {
            return nil
        }
        return statusStateValue
    }
}
