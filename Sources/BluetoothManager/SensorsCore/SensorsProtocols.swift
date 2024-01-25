import Foundation
import CoreBluetooth
import UIKit

public protocol EquipmentSensorType {
    var activityString: String { get }
    var rawValue: Int { get }
}

public enum TemperatureSensorType: Int, EquipmentSensorType, Equatable {
    case incoming = 1, outgoing
    
    public var activityString: String {
        return ""
    }
}

public protocol SensorBaseProtocol {
    var mfgId: String { get }
    var productType: String { get }
    var serialNumber: String { get }
    var statusBitmap: String { get }
    var deviceName: String { get }
    var signalStrength: Signal { get }
    var peripheral: CBPeripheral { get }
    var connectedState: CBPeripheralState { get set }
    var sensorType: SensorType { get }
    var timeStamp: Date { get set }
    var signalStrengthColor: UIColor? { get }
    var signalStrengthDescription: String { get }
}

public protocol PurgeProtocol: SensorBaseProtocol {
    var patm: Double? { get }
    var oxygenPercentage: Double? { get }
    var durationOfPurge: String { get }
    var oxygenConcentration: Double? { get }
    var type: PurgeSensorType { get set }
    var calibrating: Bool { get }
    var statusState: Int? { get }
}

public protocol ChillerProtocol: SensorBaseProtocol {
    var temperature: Double? { get }
    var type: TemperatureSensorType { get set }
}

public protocol DOProtocol: SensorBaseProtocol {
    var temperature: Double? { get }
    var oxygenConcentration: Double? { get }
    var duration: String { get }
}
