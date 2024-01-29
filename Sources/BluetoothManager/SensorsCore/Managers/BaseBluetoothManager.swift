import Foundation
import CoreBluetooth

open class BaseBluetoothManager: NSObject, BluetoothManagerProtocol {
    
    @Published public var sensorsData: [SensorBaseProtocol] = []
    @Published public var sensorData: SensorBaseProtocol?
    
    //MARK: Properties
    public var peripheral: CBPeripheral?
    public var peripheralManager: CBPeripheralManager?
    public var centralManager: CBCentralManager?
    public var connectionTimer: Timer?
    public var connectionActivated = false
    public var fromStart = false
    
    //MARK: Methods
    
    public func startAdvertising() { }
    public func stopAdvertising() { }
    
    public func startScanning(base: Bool) {
        print("startScanning \(Self.description()) **********************")
        resetServices()
        restartStanning()
        
        guard base else {
            return
        }
        
        if centralManager?.isScanning != true {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    public func restartStanning() {
        print("restartStanning \(Self.description()) **********************")
    }
    
    public func stopScanning(reset: Bool = false) {
        print("stopScanning \(Self.description()) **********************")
        centralManager?.stopScan()
        
        guard reset else {
            return
        }
        _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
            self?.restartStanning()
        })
    }
    
    public func connect(peripheral: CBPeripheral, fromStart: Bool) {
        print("connecting **********************")
        
        centralManager?.stopScan()
        
        connectionActivated = true
        self.fromStart = fromStart
        self.peripheral = peripheral
        centralManager?.connect(peripheral)
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0,
                                               repeats: false,
                                               block: { [weak self] _ in
            self?.centralManager?.cancelPeripheralConnection(peripheral)
        })
    }
    
    public func disconnect(peripheral: CBPeripheral) {
        peripheral.delegate = nil
        connectionActivated = false
        centralManager?.cancelPeripheralConnection(peripheral)
        resetServices()
        stopConnectionTimer()
        self.peripheral = nil
    }
    
    public func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
    }
    
    public func resetServices() {
        stopConnectionTimer()
    }
    
    func setSensorData(peripheral: CBPeripheral, rssi: NSNumber,
                       data: Data, dict: [String: Any]) {
        let bytesArray = data.map { String(format: "%02X", $0) }
        guard let sensor = SensorType.creatObject(peripheral: peripheral,
                                                  rssi: rssi,
                                                  hexs: bytesArray,
                                                  dataBytes: data) else {
            return
        }
        updateSensorsData(sensor: sensor)
    }
    
    private func updateSensorsData(sensor: SensorBaseProtocol) {
        if let index = sensorsData.firstIndex(where: { $0.serialNumber == sensor.serialNumber }) {
            sensorsData[index] = sensor
        } else {
            sensorsData.append(sensor)
        }
        sensorData = sensor
    }

}

extension BaseBluetoothManager: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            if peripheral.isAdvertising {
                peripheral.stopAdvertising()
            }
        } else {
            bluetoothError(peripheral.state)
        }
    }
}

extension BaseBluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if central.isScanning {
                central.stopScan()
            }
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        } else {
            bluetoothError(central.state)
        }
    }
    
    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        
        let adData = AdvertisementData(advertisementData: advertisementData)
        if let manufacturerData = adData.manufacturerData {
            setSensorData(peripheral: peripheral,
                          rssi: RSSI,
                          data: manufacturerData,
                          dict: advertisementData)
        }
    }
}
