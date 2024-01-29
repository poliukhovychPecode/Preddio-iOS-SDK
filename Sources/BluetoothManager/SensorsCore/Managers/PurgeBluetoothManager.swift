import Foundation
import CoreBluetooth

public struct PurgeActivityInput {
    public var startOxygenPercent: Double?
    public var startPressureMbar: Double?
    public var startAtmosphericPressureMbar: Int?
    public var type: String = ""
    public var method: String = ""
    
    public init() { }
    
    public var startOxygenPpb: Int? {
        guard let startPressureMbar = startPressureMbar else {
            return nil
        }
        return Int(startPressureMbar * 40.0)
    }
}

public enum PurgeBluetoothState: Equatable {
    case stop
    case connecting
    case connected
    case failed
    case disconnected
    case success
    
    // Update Characteristic
    case startUpdateCharacteristic
    case stopUpdateCharacteristic
    case characteristicFetched
    case characteristicRead
    case characteristicUpdated
    case readyToStart
    
    // Update sensor
    case needToUpdate
    case startUpdating
    case updating(percentage: Int)
    case updated
    case closeUpdate
    case failToUpdate
    
    // Calibrate sensor
    case needToCalibrate(lastDate: String)
    case startingCalibration
    case calibrationSuccess
}

public final class PurgeBluetoothManager: BaseBluetoothManager {
    
    //MARK: Properties
    @Published public var state: PurgeBluetoothState = .stop
    @Published public var offset: Double?
    @Published public var lastCalibrated: Int?
    
    internal var purgeSensorService: PurgeSensorService?
    internal var updateSensorService: SensorUpdateService?
    internal var calibrationService: CalibrationService?
    internal var otaService: OTAService?
    private var startReadPurgeInfo = false
    
    public var activityInput: PurgeActivityInput?
    public var needToCheckUpdate = false
    public var needToCheckCalibrate = false
    
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
        
        stopConnectionTimer()
        purgeSensorService = nil
        updateSensorService = nil
        calibrationService = nil
        otaService = nil
    }
    
    //MARK: Characteristic set
    
    public func setStartCharacteristic(_ peripheral: CBPeripheral?, position: Int) {
        guard let peripheral = peripheral else {
            return
        }
        state = .startUpdateCharacteristic
        needToCheckUpdate = false
        needToCheckCalibrate = false
        
        switch position {
        case 1: purgeSensorService?.writePurgeStartCharacteristic(in: peripheral)
        case 2: purgeSensorService?.writeReversePurgeStartCharacteristic(in: peripheral)
        default: break
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
        var list: [CBUUID] = [CBUUID(string: PeripheralService.MainService)]
        
        if start {
            list.append(CBUUID(string: PeripheralService.PurgeUpdateService))
            list.append(CBUUID(string: PeripheralService.OTAService))
            list.append(CBUUID(string: PeripheralService.CalibrationService))
        }
        peripheral.discoverServices(list)
    }
    
    public func fetchPurgeOxygen(_ peripheral: CBPeripheral?) {
        guard let peripheral = self.peripheral else {
            return
        }
        purgeSensorService?.readOxygenCharacteristic(in: peripheral)
    }
    
    public func setCalibrationRequestCharacteristic(_ peripheral: CBPeripheral?) {
        guard let peripheral = peripheral else {
            return
        }
        state = .startingCalibration
        needToCheckUpdate = false
        
        if let calibrationService = calibrationService {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                calibrationService.writeCalibrationRequestCharacteristic(in: peripheral)
            }
        }
    }
    
    public func getLastCalibration() {
        guard let peripheral = peripheral else {
            return
        }
        
        if let calibrationService = calibrationService {
            calibrationService.readLastCalibrationCharacteristic(in: peripheral)
        }
    }
    
    public func readCalibrationCharacteristics() {
        guard let peripheral = peripheral else {
            return
        }
        startReadPurgeInfo = true
        state = .startUpdateCharacteristic
        if let calibrationService = calibrationService {
            calibrationService.readLastCalibrationCharacteristic(in: peripheral)
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
    
    private func performUpdate() {
        guard let peripheral = peripheral else {
            return
        }
        otaService?.update(peripheral, completion: { [weak self] result in
            if result == 100 {
                self?.state = .updated
            } else if result == 101 {
                self?.state = .closeUpdate
            } else {
                self?.state = .updating(percentage: result)
            }
        })
    }
    
    public func cancelUpdate() {
        otaService?.cancelUpdate()
    }
    
}

extension PurgeBluetoothManager {
    
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
        switch state {
        case .needToUpdate, .startUpdating, .updated, .updating:
            state = .failToUpdate
        default:
            break
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

extension PurgeBluetoothManager: CBPeripheralDelegate {
    
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
            if let purgeSensorService = purgeSensorService, !purgeSensorService.hasCharacteristics {
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                purgeSensorService = PurgeSensorService()
                peripheral.discoverCharacteristics(nil, for: service)
            }
            if service.uuid.uuidString == PeripheralService.PurgeUpdateService {
                needToCheckUpdate = true
                if let updateService = updateSensorService, !updateService.hasCharacteristics {
                    
                } else {
                    updateSensorService = SensorUpdateService()
                }
                peripheral.discoverCharacteristics(nil, for: service)
            }
            if service.uuid.uuidString == PeripheralService.OTAService {
                if let otaService = otaService, !otaService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    otaService = OTAService()
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            if service.uuid.uuidString == PeripheralService.CalibrationService {
                if let calibrationService = calibrationService, !calibrationService.hasCharacteristics {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    calibrationService = CalibrationService(serviceUUID: service.uuid)
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
        guard let serviceCharacteristics = service.characteristics else {
                return
        }
        switch service.uuid.uuidString {
        case PeripheralService.MainService:
            if let purgeSensorService = purgeSensorService {
                purgeSensorService.fetchCharacteristics(serviceCharacteristics)
            }
            if !needToCheckUpdate {
                state = .characteristicFetched
            }
        case PeripheralService.PurgeUpdateService:
            if needToCheckUpdate, let updateSensorService = updateSensorService {
                updateSensorService.fetchCharacteristics(in: peripheral,
                                                         serviceCharacteristics: serviceCharacteristics)
            }
        case PeripheralService.OTAService:
            if needToCheckUpdate, let otaService = otaService {
                otaService.fetchCharacteristics(serviceCharacteristics)
            }
        case PeripheralService.CalibrationService:
            if let calibrationService = calibrationService {
                calibrationService.fetchCharacteristics(serviceCharacteristics, in: peripheral)
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
        guard error == nil else {
            debugLog("Characteristic write fail with error: \(error?.localizedDescription)")
            switch state {
            case .updating: state = .failToUpdate
            default: state = .failed
            }
            return
        }
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
        case .startingCalibration:
            state = .calibrationSuccess
        default:
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
        
        let uuidString = characteristic.uuid.uuidString
        if uuidString == PeripheralService.PurgeOxygen {
            readOxygenValue(characteristic)
        } else if uuidString == PeripheralService.CalibrationLast && startReadPurgeInfo {
            fetchLastCalibration(characteristic.value, returned: true)
        } else if uuidString == PeripheralService.CalibrationOffset && startReadPurgeInfo {
            fetchOffsetCalibration(characteristic.value)
        } else if uuidString == PeripheralService.PurgePressureMbar && startReadPurgeInfo {
            readPressureMbarValue(characteristic)
        } else if uuidString == PeripheralService.AtmosphericPressure && startReadPurgeInfo {
            readAtmosphericPressureValue(characteristic)
        } else {
            readPurgeSensorData(characteristic)
        }
    }
    
}

extension PurgeBluetoothManager {
    
    private func readOxygenValue(_ characteristic: CBCharacteristic) {
        guard let bytesArray = characteristic.value?.map({ String(format: "%02X", $0) }) else {
            return
        }
        
        if bytesArray[0] == "FF" && bytesArray[1] == "FF" {
            return
        } else {
            activityInput = PurgeActivityInput()
            if let oxygenLevel = Int((bytesArray[1] + bytesArray[0]), radix: 16) {
                activityInput?.startOxygenPercent = Double(oxygenLevel) / 128.0
            }
            fetchPurgeSensorInfo()
        }
    }
    
    private func readPressureMbarValue(_ characteristic: CBCharacteristic) {
        guard let bytesArray = characteristic.value?.map({ String(format: "%02X", $0) }),
              let pressureMbarLevel = Int((bytesArray[1] + bytesArray[0]), radix: 16)  else {
            return
        }
        activityInput?.startPressureMbar = Double(pressureMbarLevel) / 128.0
    }
    
    private func readAtmosphericPressureValue(_ characteristic: CBCharacteristic) {
        guard let bytesArray = characteristic.value?.map({ String(format: "%02X", $0) }) else {
            return
        }
        
        if let pressureLevel = Int((bytesArray[1] + bytesArray[0]), radix: 16) {
            activityInput?.startAtmosphericPressureMbar = Int(pressureLevel)
        }
        startReadPurgeInfo = false
        state = .readyToStart
    }
    
    private func fetchPurgeSensorInfo() {
        guard let peripheral = peripheral,
              let purgeSensorService = purgeSensorService else {
            state = .readyToStart
            return
        }
        purgeSensorService.readPurgeInfo(in: peripheral)
    }
    
    private func readPurgeSensorData(_ characteristic: CBCharacteristic) {
        guard state != .startUpdateCharacteristic else {
            fetchCalibrationData(characteristic)
            return
        }
        
        guard needToCheckUpdate else {
            if needToCheckCalibrate,
               characteristic.uuid.uuidString == PeripheralService.CalibrationLast {
                fetchLastCalibration(characteristic.value)
            } else {
                if state == .startUpdateCharacteristic || state == .characteristicFetched {
                    fetchCalibrationData(characteristic)
                } else {
                    state = .characteristicUpdated
                }
            }
            
            return
        }
        
        performVersionCheck(characteristic.value)
        performCalibrationCheck(characteristic.value)
    }
    
    private func fetchCalibrationData(_ characteristic: CBCharacteristic) {
        if characteristic.uuid.uuidString == PeripheralService.CalibrationLast {
            fetchLastCalibration(characteristic.value, returned: true)
        } else if characteristic.uuid.uuidString == PeripheralService.CalibrationOffset {
            fetchOffsetCalibration(characteristic.value)
        }
    }
    
    private func performVersionCheck(_ data: Data?) {
        guard let data = data, let string = String(bytes: data, encoding: .utf8) else {
            needToCheckUpdate = false
            state = .connected
            state = .characteristicFetched
            return
        }
        
        let versions = string
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let compareVersions = Constant.currentPurgeSensorVersion
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let majorEquil = versions[0] == compareVersions[0]
        let minorEquil = versions[1] == compareVersions[1]
        
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
    
    private func performCalibrationCheck(_ data: Data?) {
        guard let data = data, let string = String(bytes: data, encoding: .utf8) else {
            needToCheckCalibrate = false
            state = .connected
            state = .characteristicFetched
            return
        }
        
        let versions = string
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let compareVersions = Constant.currentPurgeCalibrationVersion
            .filter("0123456789.".contains)
            .components(separatedBy: ".")
            .compactMap { Int($0) }
        
        let majorEquil = versions[0] == compareVersions[0]
        let minorEquil = versions[1] == compareVersions[1]
        
        if compareVersions[0] > versions[0] {
            needToCheckCalibrate = false
        } else if (majorEquil && compareVersions[1] > versions[1]) {
            needToCheckCalibrate = false
        } else if (majorEquil && minorEquil && (compareVersions[2] > versions[2])) {
            needToCheckCalibrate = false
        } else {
            needToCheckCalibrate = true
        }
    }
    
    private func fetchLastCalibration(_ data: Data?, returned: Bool = false) {
        guard let data = data else {
            needToCheckCalibrate = false
            state = .connected
            state = .characteristicFetched
            if returned {
                state = .characteristicRead
            }
            return
        }
        var dataToConvert: Data = data
        if data.count > 4 {
            dataToConvert = Data(data.dropFirst(2))
        }
        
        guard !returned else {
            lastCalibrated = Int(dataToConvert.uint32)
            calibrationService?.readOffsetCalibrationCharacteristic(in: peripheral!)
            return
        }

        let date = Date(timeIntervalSince1970: TimeInterval(dataToConvert.uint32))
        let dateString = TextUtils.humanAgoDateTimeFormatted(date)
        
        state = .needToCalibrate(lastDate: dateString)
    }
    
    private func fetchOffsetCalibration(_ data: Data?) {
        guard let data = data else {
            needToCheckCalibrate = false
            state = .connected
            state = .characteristicRead
            return
        }
        var dataToConvert: Data = data
        if data.count > 4 {
            dataToConvert = Data(data.dropFirst(2))
        }
        
        offset = Double(dataToConvert.uint32) / 128.0
        state = .characteristicRead
    }
    
}
