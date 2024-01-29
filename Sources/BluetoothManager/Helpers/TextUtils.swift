import Foundation

final public class TextUtils {
    
    static func humanAgoDateTimeFormatted(_ date: Date) -> String {
        let dateTimeComponentAndValue = humanAgoDateTimeComponentAndValue(date)
        var unitName = ""
        switch dateTimeComponentAndValue {
        case (.second, 1):
            unitName = TranslationsKey.kSecond.localized
        case (.second, _):
            unitName = TranslationsKey.kSeconds.localized
        case (.minute, 1):
            unitName = TranslationsKey.kMinute.localized
        case (.minute, _):
            unitName = TranslationsKey.kMinutes.localized
        case (.hour, 1):
            unitName = TranslationsKey.kHour.localized
        case (.hour, _):
            unitName = TranslationsKey.kHours.localized
        case (.day, 1):
            unitName = TranslationsKey.kDay.localized
        case (.day, _):
            unitName = TranslationsKey.kDays.localized
        case (.weekOfMonth, 1):
            unitName = TranslationsKey.kWeek.localized
        case (.weekOfMonth, _):
            unitName = TranslationsKey.kWeeks.localized
        case (.month, 1):
            unitName = TranslationsKey.kMonth.localized
        case (.month, _):
            unitName = TranslationsKey.kMonths.localized
        case (.year, 1):
            unitName = TranslationsKey.kYear.localized
        case (.year, _):
            return ""
        default:
            return ""
        }
        return TranslationsKey.kFormatDateAgo.localizeWithFormat(dateTimeComponentAndValue.value, unitName)
    }
    
    static func humanAgoDateTimeComponentAndValue(_ date: Date) -> (component: Calendar.Component, value: Int) {
        let dateNow = Date()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute], from: date, to: dateNow)
        
        switch components {
        case _ where components.year! > 0:
            return (component: .year, value: components.year!)
        case _ where components.month! > 0:
            return (component: .month, value: components.month!)
        case _ where components.weekOfMonth! > 0:
            return (component: .weekOfMonth, value: components.weekOfMonth!)
        case _ where components.day! > 0:
            return (component: .day, value: components.day!)
        case _ where components.hour! > 0:
            return (component: .hour, value: components.hour!)
        case _ where components.minute! > 0:
            return (component: .minute, value: components.minute!)
        default:
            return (component: .minute, value: 1)
        }
    }
    
}
