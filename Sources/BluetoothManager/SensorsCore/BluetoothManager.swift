import Foundation
import CoreBluetooth
import Combine
 
public protocol BluetoothManagerProtocol {
    var sensorsData: [SensorBaseProtocol] { get set }
    var sensorData: SensorBaseProtocol? { get }
    var peripheral: CBPeripheral? { get set }
    var peripheralManager: CBPeripheralManager? { get set }
    var centralManager: CBCentralManager? { get set }
    var connectionTimer: Timer? { get set }
    var connectionActivated: Bool { get set }
    var fromStart: Bool { get set }
    
    func bluetoothError(_ state: CBManagerState)
    func startAdvertising()
    func stopAdvertising()
    func startScanning(base: Bool)
    func restartStanning()
    func stopScanning(reset: Bool)
    func connect(peripheral: CBPeripheral, fromStart: Bool)
    func disconnect(peripheral: CBPeripheral)
    func stopConnectionTimer()
    func resetServices()
    
}

public extension BluetoothManagerProtocol {
    
    func bluetoothError(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            break
        case .poweredOff:
            print("Bluetooth is off")
            break
        case .unsupported:
            print("Bluetooth is not supported")
            break
        default:
            print("Bluetooth error")
            break
        }
    }

}
