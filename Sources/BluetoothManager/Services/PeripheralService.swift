import Foundation

public enum PeripheralService {
    
    public static let MainService          = "09E02000-300E-1B1C-1C17-111E0B151B0D"
    
    //MARK: Chiller
    public static let ChillerLowAlarm      = "09E02002-300E-1B1C-1C17-111E0B151B0D"
    public static let ChillerHighAlarm     = "09E02003-300E-1B1C-1C17-111E0B151B0D"
    public static let ChillerDuration      = "09E02004-300E-1B1C-1C17-111E0B151B0D"
    
    // Purge
    public static let PurgeStart           = "09E02004-300E-1B1C-1C17-111E0B151B0D"
    //publicReverse Purge
    public static let ReversePurgeStart    = "09E02005-300E-1B1C-1C17-111E0B151B0D"
    public static let PurgeStop            = "09E02006-300E-1B1C-1C17-111E0B151B0D"
    public static let PurgeOxygen          = "09E02007-300E-1B1C-1C17-111E0B151B0D"
    public static let PurgePressureMbar    = "09E02008-300E-1B1C-1C17-111E0B151B0D"
    public static let AtmosphericPressure  = "09E0200A-300E-1B1C-1C17-111E0B151B0D"
    
    // Update
    public static let PurgeUpdateService   = "09E00100-300E-1B1C-1C17-111E0B151B0D"
    public static let SensorUpdate         = "09E00103-300E-1B1C-1C17-111E0B151B0D"
    
    // OTA
    public static let OTAService           = "1D14D6EE-FD63-4FA1-BFA4-8F47B42119F0"
    public static let OTAControl           = "F7BF3564-FB6D-4E53-88A4-5E37E0326063"
    public static let OTAData              = "984227F3-34FC-4045-A5D0-2C581F81A153"
    
    // Update
    public static let CalibrationService   = "09E02200-300E-1B1C-1C17-111E0B151B0D"
    public static let CalibrationRequest   = "09E02201-300E-1B1C-1C17-111E0B151B0D"
    public static let CalibrationLast      = "09E02204-300E-1B1C-1C17-111E0B151B0D"
    public static let CalibrationOffset    = "09E02205-300E-1B1C-1C17-111E0B151B0D"
    
    // DO
    public static let DOInterval           = "09E02001-300E-1B1C-1C17-111E0B151B0D"
    public static let DODuration           = "09E02002-300E-1B1C-1C17-111E0B151B0D"
    public static let DOSessionDuration    = "09E02003-300E-1B1C-1C17-111E0B151B0D"
    public static let DOSessionState       = "09E02004-300E-1B1C-1C17-111E0B151B0D"
    public static let DOStop               = "09E02005-300E-1B1C-1C17-111E0B151B0D"
    public static let DOOxygenCount        = "09E02006-300E-1B1C-1C17-111E0B151B0D"
    public static let DOMaxOxygenCount     = "09E02007-300E-1B1C-1C17-111E0B151B0D"
    public static let DOMinOxygenCount     = "09E02008-300E-1B1C-1C17-111E0B151B0D"
    public static let DOAvgOxygenCount     = "09E02009-300E-1B1C-1C17-111E0B151B0D"
    public static let DOTemperature        = "09E0200A-300E-1B1C-1C17-111E0B151B0D"
    public static let DOMaxTemperature     = "09E0200B-300E-1B1C-1C17-111E0B151B0D"
    public static let DOMinTemperature     = "09E0200C-300E-1B1C-1C17-111E0B151B0D"
    public static let DOAvgTemperature     = "09E0200D-300E-1B1C-1C17-111E0B151B0D"
}

