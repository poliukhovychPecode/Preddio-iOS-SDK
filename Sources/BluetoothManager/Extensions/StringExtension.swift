import Foundation

extension String {
    
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    public func localizeWithFormat(_ arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    public var trimmed: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    public var trimmerSideSpace: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var phoneNumber: String {
        return self.components(separatedBy: CharacterSet(charactersIn: "+0123456789").inverted).joined()
    }
    
    public func compare(withRegEx value: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: value)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, range: range) != nil
     }
    
    public func compare(withHex s2: String) -> Bool {
        let hexOneT = self.replacingOccurrences(of: "0x", with: "")
        let hexTwoT = s2.replacingOccurrences(of: "0x", with: "")
        return (hexOneT == hexTwoT)
    }
    
    public var isValidEmail: Bool {
          let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
          let checkEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
          return checkEmail.evaluate(with: self)
    }
    
    public func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    public var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}


public func debugLog(_ object: Any, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
  #if DEBUG
    let className = (fileName as NSString).lastPathComponent
    print("<\(className)> \(functionName) [#\(lineNumber)]| \(object)\n")
  #endif
}


extension Int {
    
    var dateString: String? {
        let epochTime = TimeInterval(self) / 1000
        let date = Date(timeIntervalSince1970: epochTime)
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/YYYY"
        let dateString = dayTimePeriodFormatter.string(from: date)
        return dateString
    }
}
