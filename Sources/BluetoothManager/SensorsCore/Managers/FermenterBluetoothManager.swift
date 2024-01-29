import Foundation
import CoreBluetooth

public enum FermenterBluetoothState {
    case stop
    case connecting
    case connected
    case failed
    case disconnected
    case success
    
    // Characteristic
    case startUpdateCharacteristic
    case stopUpdateCharacteristic
    case characteristicFetched
    case characteristicUpdated
    case readyToStart
}

public final class FermenterBluetoothManager: BaseBluetoothManager {
    
    //MARK: Properties
    @Published public var state: FermenterBluetoothState = .stop
    internal var sensorService: FermenterSensorService?
    
    //MARK: Methods
    
    public override func startAdvertising() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    public override func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    public override func startScanning() {
        super.startScanning()
        sensorsData.removeAll()
        sensorData = nil
    }
    
    public override func restartStanning() {
        super.restartStanning()
        if centralManager?.isScanning != true {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    public override func connect(peripheral: CBPeripheral, fromStart: Bool = true) {
        state = .connecting
        super.connect(peripheral: peripheral, fromStart: fromStart)
    }
    
    public override func resetServices() {
        super.resetServices()
        sensorService = nil
    }
    
    //MARK: Characteristic set
    
    public func setStartCharacteristic(_ peripheral: CBPeripheral?, position: Int) {
        guard let peripheral = peripheral else {
            return
        }
        state = .startUpdateCharacteristic
        sensorService?.writeReversePurgeStartCharacteristic(in: peripheral)
    }
    
    private func setPeripheralDelegate(_ peripheral: CBPeripheral, start: Bool) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        peripheral.delegate = self
        let list: [CBUUID] = [CBUUID(string: PeripheralService.MainService)]
        peripheral.discoverServices(list)
    }
    
    public func fetchPurgeOxygen(_ peripheral: CBPeripheral?) {
        guard let peripheral = self.peripheral else {
            return
        }
        sensorService?.readOxygenCharacteristic(in: peripheral)
    }
    
}

extension FermenterBluetoothManager: CBCentralManagerDelegate {
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
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("********************  Connected \(peripheral.identifier)")
        self.peripheral = peripheral
        stopConnectionTimer()
        setPeripheralDelegate(peripheral, start: fromStart)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect")
        state = .failed
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral")
        guard connectionActivated else {
            state = .disconnected
            return
        }
        resetServices()
        stopAdvertising()
        startAdvertising()
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.peripheral = self.sensorsData.first(where: { $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString })?.peripheral
            guard let peripheral = self.peripheral else {
                startScanning()
                return
            }
            self.connect(peripheral: peripheral, fromStart: true)
        })
    }
    
    private func readOxygenValue(_ characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
        let bytesArray = data.map { String(format: "%02X", $0) }
        
        if bytesArray[0] == "FF" && bytesArray[1] == "FF" {
            return
        } else {
            state = .readyToStart
        }
    }
    
}

extension FermenterBluetoothManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        
        guard let peripheralServices = peripheral.services else {
            return
        }
        for service in peripheralServices {
            print("Service: \(service.uuid)")
            if let fermenterService = sensorService, !fermenterService.hasCharacteristics {
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                sensorService = FermenterSensorService()
                peripheral.discoverCharacteristics(nil, for: service)
            }
            state = .connected
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        guard let serviceCharacteristics = service.characteristics else {
            return
        }
        sensorService?.fetchCharacteristics(serviceCharacteristics)
        state = .characteristicFetched
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        if let error = error {
            print("Characteristic write fail with error: \(error.localizedDescription)")
            state = .failed
        } else {
            print("Characteristic didWriteValueFor: \(characteristic)")
            state = .characteristicUpdated
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        print("Characteristic didUpdateValueFor: \(characteristic)")
        readOxygenValue(characteristic)
    }
    
}
