import Foundation
import CoreBluetooth

final public class FermenterSensorService {
    
    private var reversePurgeStartUUID = PeripheralService.ReversePurgeStart
    private var reversePurgeStartCBCharacteristic: CBCharacteristic?
    
    private var purgeStopUUID = PeripheralService.PurgeStop
    private var purgeStopCBCharacteristic: CBCharacteristic?
    
    private var purgeOxygenUUID = PeripheralService.PurgeOxygen
    private var purgeOxygenCBCharacteristic: CBCharacteristic?

    public var hasCharacteristics: Bool {
        return reversePurgeStartCBCharacteristic != nil
                && purgeStopCBCharacteristic != nil
                && purgeOxygenCBCharacteristic != nil
    }
    
    public init() { }
    
    //MARK: Reverse Purge Fetch Characteristic
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic]) {
        guard !hasCharacteristics else {
            return
        }
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic Reverse Purge: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case reversePurgeStartUUID:
                reversePurgeStartCBCharacteristic = characteristic
            case purgeStopUUID:
                purgeStopCBCharacteristic = characteristic
            case purgeOxygenUUID:
                purgeOxygenCBCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: Reverse Purge Characteristic Write Methods
    
    public func writeReversePurgeStartCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = reversePurgeStartCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Reverse Pugre Start: \(characteristic)")
        var timestamp = UInt32(Date().timeIntervalSince1970)
        let data: Data = Data(bytes: &timestamp,
                              count: MemoryLayout.size(ofValue: timestamp))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func writePurgeStopCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = purgeStopCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Reverse Purge Stop: \(characteristic)")
        var zero = UInt8(0)
        let data: Data = Data(bytes: &zero,
                              count: MemoryLayout.size(ofValue: zero))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    //MARK: Reverse Purge Characteristic Read Methods
    
    public func readOxygenCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = purgeOxygenCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Reverse Purge Oxygen: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
}
