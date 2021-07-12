public struct FlightplanItem: Codable {
    public init(identifier: String, type: String, latitude: Float, longitude: Float, elevation: Float? = nil) {
        self.identifier = identifier
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
    
    public var identifier: String
    ///Possible variants: USER VARIANT, AIRPORT, NDB, VOR. Garmin also uses INT, INT-VRP
    public var type: String
    public var latitude: Float
    public var longitude: Float
    /// Elevation in meters
    public var elevation: Float?
    
    public var elevationInFeet: Float? {
        get {
            if elevation != nil {
                return elevation! * 3.28084
            }
            return nil
        }
        
        set {
            if newValue != nil {
                elevation = newValue! / 3.28084
            } else {
                elevation = nil
            }
        }
    }
}

extension FlightplanItem {
    internal init() {
        self.identifier = ""
        self.type = ""
        self.latitude = 1000
        self.longitude = 1000
    }
    
    internal var hash: String {
        return "\(self.latitude)\(self.longitude)\(self.elevation ?? -1000000)\(self.type)"
    }
}

internal struct RouteItem {
    var identifier: String
    var type: String
}

extension RouteItem {
    internal init() {
        self.identifier = ""
        self.type = ""
    }
}
