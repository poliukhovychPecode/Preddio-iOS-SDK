import Foundation
import CoreBluetooth

final public class SensorUpdateService {
    
    private var updateUUID = PeripheralService.SensorUpdate
    private(set) var updateCBCharacteristic: CBCharacteristic?
    
    public var hasCharacteristics: Bool {
        return updateCBCharacteristic != nil
    }
    
    public init() { }
    
    //MARK: Sensor Update Fetch Characteristic
    
    public func fetchCharacteristics(in peripheral: CBPeripheral, serviceCharacteristics: [CBCharacteristic]) {
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic Sensor Update: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case updateUUID:
                updateCBCharacteristic = characteristic
                readUpdateCharacteristic(in: peripheral)
            default: break
            }
        }
    }
    
    //MARK: Sensor Update Characteristic Read Methods
    
    public func readUpdateCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = updateCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Sensor Update: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
}
