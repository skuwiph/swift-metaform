//
//  FormData.swift
//  
//
//  Created by Ian Seckington on 10/03/2020.
//

import Foundation

public class MetaFormData {
    private var data = [String: String]()
    private var forceLowerCase = false
    
    func getValue(_ name: String) -> String {
        let fieldName = self.correctFieldName(name: name)
        return self.data[fieldName] ?? ""
    }
    
    func setValue(_ name: String, value: String) {
        let fieldName = self.correctFieldName(name: name)
        
        let oldValue = getValue(name)
        self.data[fieldName] = value
        
        let fdc = FormDataChanged(fieldName: name, oldValue: oldValue, newValue: value)
        NotificationCenter.default.post(name: NSNotification.Name.dataWasChanged, object: self, userInfo: [ "data" : fdc])
    }
    
    func getValueAsDate(_ name: String) -> Date? {
        let value = self.getValue(name)
        return self.getAsDateTime(value)
    }
    
    // Todo(Ian): This is the same as the above in the typescript
    // version too...?
    func getValueAsDateTime(_ name: String) -> Date? {
        let value = self.getValue(name)
        return self.getAsDateTime(value);
    }
    
    func getAsDateTime(_ value: String) -> Date? {
        let datePart = MFDateControl.getDatePart(value)
        var timePart: String? = nil
        if value.contains(":") {
            timePart = MFTimeControl.getTimePart(value)
        }
        return self.convertValueToDate(datePart, timeValue: timePart)
    }
    
    func convertValueToDate(_ value: String, timeValue: String? = nil) -> Date? {
        let year = MFDateControl.getYearFrom(value)
        let month = MFDateControl.getMonthFrom(value)
        let day = MFDateControl.getDayFrom(value)
        
        var hour = 0
        var mins = 0
        if timeValue != nil {
            hour = Int(MFTimeControl.getHourPart(timeValue!)) ?? -1
            mins = Int(MFTimeControl.getMinutePart(timeValue!)) ?? -1
        }
        
        if year.isEmpty || month.isEmpty || day.isEmpty || hour == -1 || mins == -1 {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.locale = Locale.init(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let dc = DateComponents(calendar: calendar, year: Int(year), month: Int(month), day: Int(day), hour: hour, minute: mins, second: 0)
        // print("\(value) is valid? \(dc.isValidDate(in: calendar))")
        if dc.isValidDate(in: calendar) {
            let date = calendar.date(from: dc)
            return date
        } else {
            return nil
        }
    }
    
    private func correctFieldName(name: String) -> String {
        return self.forceLowerCase ? name.lowercased() : name
    }
}
