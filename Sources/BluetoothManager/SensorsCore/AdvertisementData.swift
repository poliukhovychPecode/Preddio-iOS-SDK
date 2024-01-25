import Foundation
import CoreBluetooth

public struct AdvertisementData {

    public let advertisementData: [String: Any]

    public init(advertisementData: [String: Any]) {
        self.advertisementData = advertisementData
    }

    public var localName: String? {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    public var manufacturerData: Data? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }

    public var serviceData: [CBUUID: Data]? {
        return advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }

    public var serviceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }

    public var overflowServiceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }

    public var txPowerLevel: NSNumber? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }

    public var isConnectable: Bool? {
        return advertisementData[CBAdvertisementDataIsConnectable] as? Bool
    }

    public var solicitedServiceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}

