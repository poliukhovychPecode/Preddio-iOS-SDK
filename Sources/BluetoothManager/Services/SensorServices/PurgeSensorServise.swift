import Foundation
import CoreBluetooth

final public class PurgeSensorService {
    
    private var purgeStartUUID = PeripheralService.PurgeStart
    private var purgeStartCBCharacteristic: CBCharacteristic?
    
    private var reversePurgeStartUUID = PeripheralService.ReversePurgeStart
    private var reversePurgeStartCBCharacteristic: CBCharacteristic?
    
    private var purgeStopUUID = PeripheralService.PurgeStop
    private var purgeStopCBCharacteristic: CBCharacteristic?
    
    private var purgeOxygenUUID = PeripheralService.PurgeOxygen
    private var purgeOxygenCBCharacteristic: CBCharacteristic?
    
    private var pressureMbarUUID = PeripheralService.PurgePressureMbar
    private var pressureMbarCBCharacteristic: CBCharacteristic?
    
    private var atmosphericPressureMbarUUID = PeripheralService.AtmosphericPressure
    private var atmosphericPressureMbarCBCharacteristic: CBCharacteristic?
    
    public var hasCharacteristics: Bool {
        return purgeStartCBCharacteristic != nil &&
                reversePurgeStartCBCharacteristic != nil &&
                purgeStopCBCharacteristic != nil &&
                purgeOxygenCBCharacteristic != nil
    }
    
    public init() { }
    
    //MARK: Purge Fetch Characteristic
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic]) {
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic Purge: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case purgeStartUUID:
                purgeStartCBCharacteristic = characteristic
            case reversePurgeStartUUID:
                reversePurgeStartCBCharacteristic = characteristic
            case purgeStopUUID:
                purgeStopCBCharacteristic = characteristic
            case purgeOxygenUUID:
                purgeOxygenCBCharacteristic = characteristic
            case pressureMbarUUID:
                pressureMbarCBCharacteristic = characteristic
            case atmosphericPressureMbarUUID:
                atmosphericPressureMbarCBCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: Purge Write Characteristic Methods
    
    public func writePurgeStartCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = purgeStartCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Pugre Start: \(characteristic)")
        var timestamp = UInt32(Date().timeIntervalSince1970)
        let data: Data = Data(bytes: &timestamp,
                              count: MemoryLayout.size(ofValue: timestamp))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
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
        
        debugLog("Characteristic Stop: \(characteristic)")
        var zero = UInt8(0)
        let data: Data = Data(bytes: &zero,
                              count: MemoryLayout.size(ofValue: zero))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    //MARK: Purge Read Characteristic Methods
    
    public func readOxygenCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = purgeOxygenCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Oxygen: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
    public func readPurgeInfo(in peripheral: CBPeripheral) {
        readPressureMbarCharacteristic(in: peripheral)
        readAtmosphericPressureMbarCharacteristic(in: peripheral)
    }
    
    private func readPressureMbarCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = pressureMbarCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Pressure Mbar: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
    private func readAtmosphericPressureMbarCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = atmosphericPressureMbarCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Atmospheric Pressure Mbar: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
}
