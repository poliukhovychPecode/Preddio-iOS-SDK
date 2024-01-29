import Foundation
import CoreBluetooth

final public class OTAService {
    
    private let otaControlUUID = PeripheralService.OTAControl
    private var otaControlCharacteristic: CBCharacteristic?
    
    private var otaDataUUID = PeripheralService.OTAData
    private var otaDataCharacteristic: CBCharacteristic?
    
    private var mtu = 0
    private var bytes: NSData?
    private var dataSize = 0
    private var index = 0
    private var progress = 0
    
    public var hasCharacteristics: Bool {
        return otaControlCharacteristic != nil &&
        otaDataCharacteristic != nil
    }
    
    public init() { }
    
    public func prepareToUpdate(with data: Data, peripheral: CBPeripheral) {
        index = 0
        progress = 0
        dataSize = data.count
        bytes = data as NSData
        
        mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        if mtu > 247 {
            mtu = 247
        }
        mtu = mtu - 3
        
        mtu = 180
    }
    
    public func cancelUpdate() {
        index = 0
        progress = 0
    }
    
    public func startUpdate(_ peripheral: CBPeripheral) {
        Task {
            var initCommand: UInt8 = 0
            writeControl(peripheral, data: Data(bytes: &initCommand, count: 1))
            debugLog("writeControl 00")
        }
    }
    
    public func update(_ peripheral: CBPeripheral, completion: ((Int) -> Void)?) {
        
        Task {
            
            guard index <= dataSize else {
                
                if progress < 100 {
                    progress = 100
                    try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    var resetCommand: UInt8 = 3
                    writeControl(peripheral, data: Data(bytes: &resetCommand, count: 1))
                    
                    try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    var rebootCommand: UInt8 = 4
                    writeControl(peripheral, data: Data(bytes: &rebootCommand, count: 1))
                    
                    try await Task.sleep(nanoseconds: UInt64(8 * Double(NSEC_PER_SEC)))
                    completion?(100)
                    
                    try await Task.sleep(nanoseconds: UInt64(4 * Double(NSEC_PER_SEC)))
                    completion?(101)
                }
                
                return
            }
            var packet:Data?
            let length = (bytes!.count - index > mtu) ? mtu : (bytes!.count - index)
            packet = bytes?.subdata(with: NSRange(location: index, length: length))
            writeData(peripheral, data: packet)
            
            let percentage = Int(Double(index) / Double(dataSize) * 100)
            debugLog("writeData \(percentage)")

            index += mtu
            
            progress = percentage
            completion?(percentage)
        }
    }
    
    public func fetchCharacteristics(_ serviceCharacteristics: [CBCharacteristic]) {
        for characteristic in serviceCharacteristics {
            debugLog("Characteristic: " + characteristic.uuid.uuidString)
            
            switch characteristic.uuid.uuidString {
            case otaControlUUID:
                otaControlCharacteristic = characteristic
            case otaDataUUID:
                otaDataCharacteristic = characteristic
            default: break
            }
        }
    }
    
    //MARK: OTA Characteristic Write Methods
    
    private func writeControl(_ peripheral: CBPeripheral, data: Data?) {
        guard let characteristic = otaControlCharacteristic,
              let data = data else {
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        debugLog("Characteristic Control \(data): \(characteristic)")
    }
    
    private func writeData(_ peripheral: CBPeripheral, data: Data?) {
        guard let characteristic = otaDataCharacteristic,
              let data = data else {
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        debugLog("Characteristic Data: \(characteristic)")
    }
}
