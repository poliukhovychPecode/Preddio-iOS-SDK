import Foundation
import CoreBluetooth

public enum DOBluetoothState: Equatable {
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
    
    // Update
    case needToUpdate
    case startUpdating
    case updating(percentage: Int)
    case updated
    case closeUpdate
    case failToUpdate
}

public final class DOBluetoothManager: BaseBluetoothManager {
    
    //MARK: Properties
    internal var sensorService: DOSensorService?
    internal var otaService: OTAService?
    internal var updateSensorService: SensorUpdateService?
    
    @Published public var state: DOBluetoothState = .stop
    public var allowInterval = false
    public var needToCheckUpdate = false
    
    private var doDuration = 0
    
    //MARK: Methods
    
    public override func startAdvertising() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    public override func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    public func startScanning() {
        startScanning(base: false)
        sensorsData.removeAll()
        sensorData = nil
    }
    
    public func stopScanning() {
        stopScanning(reset: false)
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
        otaService = nil
        updateSensorService = nil
        doDuration = 0
        allowInterval = false
        needToCheckUpdate = false
    }
    
    //MARK: Characteristic set
    
    private func setPeripheralDelegate(_ peripheral: CBPeripheral, start: Bool) {
        if fromStart {
            guard self.peripheral == peripheral else {
                state = state != .connecting ? .connected : .connecting
                return
            }
        }
        peripheral.delegate = self
        var list: [CBUUID] = [CBUUID(string: PeripheralService.MainService)]
        if start {
            list.append(CBUUID(string: PeripheralService.PurgeUpdateService))
            list.append(CBUUID(string: PeripheralService.OTAService))
        }
        peripheral.discoverServices(list)
    }
    
    public func setDODurationCharacteristic(_ peripheral: CBPeripheral?, duration: Int, interval: Int) {
        guard let peripheral = peripheral else {
            return
        }
        state = .startUpdateCharacteristic
        needToCheckUpdate = false
        doDuration = duration
        var interval = interval
        if allowInterval {
            sensorService?.writeIntervalCharacteristic(in: peripheral, value: &interval)
        } else {
            sensorService?.writeDurationCharacteristic(in: peripheral, value: &doDuration)
        }
    }
    
    public func updateSensor(_ peripheral: CBPeripheral?, data: Data?) {
        guard let peripheral = peripheral,
              let data = data else {
            state = .characteristicFetched
            return
        }
        
        otaService?.prepareToUpdate(with: data, peripheral: peripheral)
        state = .startUpdating
        otaService?.startUpdate(peripheral)
    }
    
    public func cancelUpdate() {
        otaService?.cancelUpdate()
    }
    
    private func performUpdate() {
        guard let peripheral = peripheral else {
            return
        }
        otaService?.update(peripheral, completion: { [weak self] result in
            switch result {
            case 100: self?.state = .updated
            case 101: self?.state = .closeUpdate
            default: self?.state = .updating(percentage: result)
            }
        })
    }
    
    private func performVersionCheck(_ data: Data?) {
        guard let data = data,
              let string = String(bytes: data, encoding: .utf8) else {
            needToCheckUpdate = false
            state = .connected
            state = .characteristicFetched
            return
        }
        
        let versions = string
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let compareVersions = Constant.currentDOSensorVersion
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let majorEquil = versions[0] == compareVersions[0]
        let minorEquil = versions[1] == compareVersions[1]
         
        if versions[0] > Constant.compareDOSensorVersion[0] {
            allowInterval = true
        } else if versions[0] == Constant.compareDOSensorVersion[0] {
            allowInterval = versions[1] >= Constant.compareDOSensorVersion[1]
        } else {
            allowInterval = false
        }
        
        if compareVersions[0] > versions[0] {
            state = .needToUpdate
        } else if majorEquil && compareVersions[1] > versions[1] {
            state = .needToUpdate
        } else if (majorEquil && minorEquil && (compareVersions[2] > versions[2])) {
            state = .needToUpdate
        } else {
            state = .connected
            state = .characteristicFetched
        }
        
        needToCheckUpdate = false
    }
    
}

extension DOBluetoothManager {

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

extension DOBluetoothManager: CBPeripheralDelegate {
    
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
            if service.uuid.uuidString == PeripheralService.MainService {
                if let doSensorService = sensorService, !doSensorService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    sensorService = DOSensorService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            if service.uuid.uuidString == PeripheralService.PurgeUpdateService {
                needToCheckUpdate = true
                if updateSensorService == nil {
                    updateSensorService = SensorUpdateService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            if service.uuid.uuidString == PeripheralService.OTAService {
                if let otaService = otaService, !otaService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    otaService = OTAService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            state = needToCheckUpdate ? .connecting : .connected
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
        guard let characteristics = service.characteristics else {
            return
        }
        switch service.uuid.uuidString {
        case PeripheralService.MainService:
            if let doSensorService = sensorService {
                doSensorService.fetchCharacteristics(characteristics, peripheral: peripheral)
            }
            if !needToCheckUpdate {
                state = .characteristicFetched
            }
        case PeripheralService.PurgeUpdateService:
            if needToCheckUpdate,
                let updateSensorService = updateSensorService, 
                !updateSensorService.hasCharacteristics {
                updateSensorService.fetchCharacteristics(in: peripheral,
                                                         serviceCharacteristics: characteristics)
            }
        case PeripheralService.OTAService:
            if needToCheckUpdate, let otaService = otaService {
                otaService.fetchCharacteristics(characteristics)
            }
        default: break
        }
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
            switch state {
            case .startUpdating:
                Task {
                    try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    performUpdate()
                }
            case .updating:
                performUpdate()
            case .closeUpdate, .updated:
                break
            default:
                sensorService?.characteristicUpdatedCount += 1
                if allowInterval {
                    if sensorService?.characteristicUpdatedCount == 1 {
                        sensorService?.writeDurationCharacteristic(in: peripheral, value: &doDuration)
                    } else {
                        state = .characteristicUpdated
                    }
                } else {
                    sensorService?.characteristicUpdatedCount += 1
                    if sensorService?.characteristicUpdatedCount == 2 {
                        state = .characteristicUpdated
                    }
                }
            }
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
        
        guard needToCheckUpdate else {
            state = .characteristicUpdated
            return
        }
        performVersionCheck(characteristic.value)
       
    }
    
}
