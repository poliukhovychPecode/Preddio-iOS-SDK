import Foundation
import CoreBluetooth

final public class CalibrationService {
    
    private var calibrationUUID = PeripheralService.CalibrationRequest
    private var calibrationCBCharacteristic: CBCharacteristic?
    
    private var calibrationLastUUID = PeripheralService.CalibrationLast
    private var calibrationLastCBCharacteristic: CBCharacteristic?
    
    private var calibrationOffsetUUID = PeripheralService.CalibrationOffset
    private var calibrationOffsetCBCharacteristic: CBCharacteristic?
    
    public var hasCharacteristics: Bool {
        return calibrationCBCharacteristic != nil &&
            calibrationLastCBCharacteristic != nil &&
            calibrationOffsetCBCharacteristic != nil
    }
    
    public init(serviceUUID: CBUUID) { }
    
    //MARK: Calibration Fetch Characteristic
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic], in peripheral: CBPeripheral) {
        guard !hasCharacteristics else {
            return
        }
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic Calibration: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case calibrationUUID:
                calibrationCBCharacteristic = characteristic
            case calibrationLastUUID:
                calibrationLastCBCharacteristic = characteristic
            case calibrationOffsetUUID:
                calibrationOffsetCBCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: Calibration Write Characteristic
    
    public func writeCalibrationRequestCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = calibrationCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Calibration Request: \(characteristic)")
        var timestamp = UInt32(Date().timeIntervalSince1970)
        let data: Data = Data(bytes: &timestamp,
                              count: MemoryLayout.size(ofValue: timestamp))
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    public func readLastCalibrationCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = calibrationLastCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Calibration Last Calibrate: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
    
    //MARK: Calibration Read Characteristic
    
    public func readOffsetCalibrationCharacteristic(in peripheral: CBPeripheral) {
        guard let characteristic = calibrationOffsetCBCharacteristic else {
            return
        }
        
        debugLog("Characteristic Calibration Offset Calibrate: \(characteristic)")
        peripheral.readValue(for: characteristic)
    }
}
