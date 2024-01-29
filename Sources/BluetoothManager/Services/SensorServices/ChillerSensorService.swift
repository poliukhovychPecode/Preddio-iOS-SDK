import Foundation
import CoreBluetooth

final public class ChillerSensorService {
    
    private var lowAlarmUUID = PeripheralService.ChillerLowAlarm
    private var lowAlarmCBCharacteristic: CBCharacteristic?
    
    private var highAlarmUUID = PeripheralService.ChillerHighAlarm
    private var highAlarmCBCharacteristic: CBCharacteristic?
    
    private var durationUUID = PeripheralService.ChillerDuration
    private var durationCBCharacteristic: CBCharacteristic?
    
    public var characteristicUpdatedCount = 0
    
    public var hasCharacteristics: Bool {
        return lowAlarmCBCharacteristic != nil 
            && highAlarmCBCharacteristic != nil
            && durationCBCharacteristic != nil
    }
    
    public init() { }
    
    //MARK: Chiller Fetch Characteristic
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic]) {
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic Chiller: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case lowAlarmUUID:
                lowAlarmCBCharacteristic = characteristic
            case highAlarmUUID:
                highAlarmCBCharacteristic = characteristic
            case durationUUID:
                durationCBCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: Chiller Characteristic Methods
     
    public func writeChillerLowAlarmCharacteristic(value: inout Int, in peripheral: CBPeripheral) {
        guard let characteristic = lowAlarmCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Chiller Low Alarm: \(characteristic)")
        let data: Data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func writeChillerHighAlarmCharacteristic(value: inout Int, in peripheral: CBPeripheral) {
        guard let characteristic = highAlarmCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Chiller High Alarm: \(characteristic)")
        let data: Data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func writeChillerDurationCharacteristic(duration: Int, in peripheral: CBPeripheral) {
        guard let characteristic = durationCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Chiller Duration: \(characteristic)")
        var timestamp = UInt16(duration)
        let data: Data = Data(bytes: &timestamp,
                              count: MemoryLayout.size(ofValue: timestamp))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}
