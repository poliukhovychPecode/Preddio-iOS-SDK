import Foundation
import CoreBluetooth

final public class DOSensorService {
    
    private var doDurationUUID = PeripheralService.DODuration
    private var doDurationCBCharacteristic: CBCharacteristic?
    
    private var doStopUUID = PeripheralService.DOStop
    private var doStopCBCharacteristic: CBCharacteristic?
    
    private var doSessionStateUUID = PeripheralService.DOSessionState
    private var doSessionStateCBCharacteristic: CBCharacteristic?
    
    private var durationUUID = PeripheralService.DOSessionDuration
    private var durationCBCharacteristic: CBCharacteristic?
    
    private var intervalUUID = PeripheralService.DOInterval
    private var intervalCBCharacteristic: CBCharacteristic?
    
    public var characteristicUpdatedCount = 0
    
    public var hasCharacteristics: Bool {
        return doDurationCBCharacteristic != nil &&
        doStopCBCharacteristic != nil
    }
    
    public init() { }
    
    //MARK: DO Fetch Characteristic
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic],
                                     peripheral: CBPeripheral) {
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic DO: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case intervalUUID:
                intervalCBCharacteristic = characteristic
            case doDurationUUID:
                doDurationCBCharacteristic = characteristic
            case doStopUUID:
                doStopCBCharacteristic = characteristic
            case doSessionStateUUID:
                doSessionStateCBCharacteristic = characteristic
            case durationUUID:
                durationCBCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: DO Characteristic Write Methods
    
    public func writeDurationCharacteristic(in peripheral: CBPeripheral, value: inout Int) {
        guard let characteristic = doDurationCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic DO Duration: \(characteristic)")
        let data: Data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func writeIntervalCharacteristic(in peripheral: CBPeripheral, value: inout Int) {
        guard let characteristic = intervalCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic DO Interval: \(characteristic)")
        var valueToWrite = UInt16(value)
        let data: Data = Data(bytes: &valueToWrite,
                              count: MemoryLayout.size(ofValue: valueToWrite))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func writeStopCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = doStopCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic DO Stop: \(characteristic)")
        var zero = UInt8(0)
        let data: Data = Data(bytes: &zero,
                              count: MemoryLayout.size(ofValue: zero))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    //MARK: DO Characteristic Read Methods
    
    public func readSessionStateCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = doSessionStateCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic DO Session State: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
    public func readDurationCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = durationCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic DO Duration: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
}
