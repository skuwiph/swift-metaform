//
//  FormData.swift
//  
//
//  Created by Ian Seckington on 10/03/2020.
//

import Foundation

class MetaFormData {
    private var data = [String: String]()
    private var forceLowerCase = false
    
    func getValue(_ name: String) -> String {
        let fieldName = self.correctFieldName(name: name)
        return self.data[fieldName] ?? ""
    }
    
    func setValue(_ name: String, value: String) {
        let fieldName = self.correctFieldName(name: name)
        self.data[fieldName] = value
    }
    
    func getValueAsDate(_ name: String) -> Date? {
        let value = self.getValue(name)
        let datePart = MFDateControl.getDatePart(value)
        let timePart = MFTimeControl.getTimePart(value)
        
        return self.convertValueToDate(datePart, timeValue: timePart)
    }
    
    // Todo(Ian): This is the same as the above in the typescript
    // version too...?
    func getValueAsDateTime(_ name: String) -> Date? {
        let value = self.getValue(name)
        let datePart = MFDateControl.getDatePart(value)
        let timePart = MFTimeControl.getTimePart(value)
        
        return self.convertValueToDate(datePart, timeValue: timePart)
    }
    
    func convertValueToDate(_ value: String, timeValue: String? = nil) -> Date? {
        let year = MFDateControl.getYearFrom(value)
        let month = MFDateControl.getMonthFrom(value)
        let day = MFDateControl.getDayFrom(value)
        
        var hour = 0
        var mins = 0
        if timeValue != nil {
            hour = Int(MFTimeControl.getHourPart(timeValue!)) ?? 0
            mins = Int(MFTimeControl.getMinutePart(timeValue!)) ?? 0
        }
        
        var dc = DateComponents()
        dc.timeZone = TimeZone(abbreviation: "UTC")
        dc.year = Int(year)
        dc.month = Int(month)
        dc.day = Int(day)
        dc.hour = hour
        dc.minute = mins
        
        let userCalendar = Calendar.current
        return userCalendar.date(from: dc)
        
    }
    
    private func correctFieldName(name: String) -> String {
        return self.forceLowerCase ? name.lowercased() : name
    }
}
