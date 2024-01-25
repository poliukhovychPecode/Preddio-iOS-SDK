import Foundation

public enum PurgeSensorType: Int, EquipmentSensorType {
    case purge = 1, reversePurge, doSensor, fermenterReversePurge, gas
    
    public var position: Int {
        switch self {
        case .purge, .fermenterReversePurge:
            return 1
        case .reversePurge:
            return 2
        case .doSensor:
            return 3
        default: return 1
        }
    }
    
    public var activityString: String {
        switch self {
        case .purge:
            return "PURGE"
        case .reversePurge, .fermenterReversePurge:
            return "REVERSE_PURGE"
        case .doSensor:
            return "DO_SESSION"
        default: return ""
        }
    }
}
