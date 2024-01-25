import Foundation
import CoreBluetooth

public enum ChillerBluetoothState {
    case stop
    case connecting
    case connected
    case failed
    case disconnected
    case success
    case startUpdateCharacteristic
    case stopUpdateCharacteristic
    case characteristicFetched
    case characteristicUpdated
    case readyToStart
}

public final class ChillerBluetoothManager: BaseBluetoothManager {
    
    //MARK: Properties
    @Published public var state: ChillerBluetoothState = .stop
    internal var sensorService: ChillerSensorService?
    
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
    
    public func setAlarmCharacteristic(_ peripheral: CBPeripheral?,
                                       low: Int, high: Int, duration: Int) {
        guard let peripheral = peripheral else {
            return
        }
        var low = low
        var high = high
        state = .startUpdateCharacteristic
        sensorService?.writeChillerLowAlarmCharacteristic(value: &low, in: peripheral)
        sensorService?.writeChillerHighAlarmCharacteristic(value: &high, in: peripheral)
        sensorService?.writeChillerDurationCharacteristic(duration: duration, in: peripheral)
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
    
}

extension ChillerBluetoothManager: CBCentralManagerDelegate {
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
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
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
    
}

extension ChillerBluetoothManager: CBPeripheralDelegate {
    
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
            if let sensorService = sensorService, !sensorService.hasCharacteristics {
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                sensorService = ChillerSensorService()
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
            sensorService?.characteristicUpdatedCount += 1
            if sensorService?.characteristicUpdatedCount == 3 {
                state = .characteristicUpdated
            }
        }
    }
    
}
