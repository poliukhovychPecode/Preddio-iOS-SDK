import Foundation
import CoreBluetooth

public enum StopEquipmentType {
    case briteTank, fermenter, doSensor
}

public enum StopBluetoothState {
    case stop
    case connecting
    case connected
    case failed
    case disconnected
    case success
    
    // Characteristic
    case stopUpdateCharacteristic
    case characteristicFetched
    case characteristicUpdated
}

public final class StopBluetoothManager: BaseBluetoothManager {
    
    //MARK: Properties
    @Published public var state: StopBluetoothState = .stop
    private var type: StopEquipmentType = .briteTank
    
    internal var purgeSensorService: PurgeSensorService?
    internal var fermenterSensorService: FermenterSensorService?
    internal var doSensorService: DOSensorService?
    
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
    
    public func connect(peripheral: CBPeripheral, type: StopEquipmentType) {
        state = .connected
        connect(peripheral: peripheral, fromStart: false)
    }
    
    public override func resetServices() {
        super.resetServices()
        doSensorService = nil
        purgeSensorService = nil
        fermenterSensorService = nil
    }
    
    //MARK: Characteristic set
    public func setStopCharacteristic(_ peripheral: CBPeripheral?) {
        guard let peripheral = self.peripheral else {
            return
        }
        state = .stopUpdateCharacteristic
        if let purgeSensorService = purgeSensorService {
            purgeSensorService.writePurgeStopCharacteristic(in: peripheral)
        }
        if let fermenterSensorService = fermenterSensorService {
            fermenterSensorService.writePurgeStopCharacteristic(in: peripheral)
        }
        if let doSensorService = doSensorService {
            doSensorService.writeStopCharacteristic(in: peripheral)
        }
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

extension StopBluetoothManager: CBCentralManagerDelegate {
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
    
}

extension StopBluetoothManager: CBPeripheralDelegate {
    
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
            switch type {
            case .briteTank:
                if let purgeSensorService = purgeSensorService, !purgeSensorService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    purgeSensorService = PurgeSensorService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            case .fermenter:
                if let fermenterService = fermenterSensorService, !fermenterService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    fermenterSensorService = FermenterSensorService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            case .doSensor:
                if let doSensorService = doSensorService, !doSensorService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    doSensorService = DOSensorService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
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
        if let purgeSensorService = purgeSensorService {
            purgeSensorService.fetchCharacteristics(serviceCharacteristics)
        }
        if let fermenterSensorService = fermenterSensorService {
            fermenterSensorService.fetchCharacteristics(serviceCharacteristics)
        }
        if let doSensorService = doSensorService {
            doSensorService.fetchCharacteristics(serviceCharacteristics, peripheral: peripheral)
        }
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
    
}
