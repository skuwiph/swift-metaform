//
//  Controls.swift
//  
//
//  Created by Ian Seckington on 09/03/2020.
//

import Foundation

class MFControl {
    var controlType: MetaFormControlType
    var controlId: String
    var name: String
    var autoComplete: String?
    
    // Optional label for certain controls
    var label: String?
    
    var validators: [MFValidator]?
    var validatorsAsync: [MFValidatorAsync]?
    
    // Internal usage
    var isReferencedBy = Set<String>()
    var references: [String] = []
    var dependencies: [String]?
    
    var readonly = false
    
    var inError = false
    var errorMessage: String?
    
    init(parent: MFQuestion, controlType: MetaFormControlType, name: String) {
        self.name = name
        self.controlType = controlType
        self.controlId = "\(parent.name):\(name)"
    }
    
    func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        var valid = true
        
        if (self.validators != nil) {
            for v in self.validators! {
                if !v.isValid(form: form, control: self) {
                    valid = false
                    self.errorMessage = v.message
                    
                    break
                }
            }
        }
        
        return valid
    }
    
    func addReferencedBy(controlName: String) {
        if !self.isReferencedBy.contains(controlName) {
            self.isReferencedBy.insert(controlName)
        }
    }
}

class MFLabel: MFControl {
    var text: String
    
    init(parent: MFQuestion, name: String, text: String) {
        self.text = text
        super.init(parent: parent, controlType: MetaFormControlType.Label, name: name)
    }

    override func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        return true;
    }
}

class MFHtmlTextControl: MFControl {
    var html: String;

    init(parent: MFQuestion, name: String, html: String) {
        self.html = html
        super.init(parent: parent, controlType: MetaFormControlType.Html, name: name)
    }

    override func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        return true;
    }
}

class MFTextControl: MFControl {
    var textType: MetaFormTextType;
    var maxLength: Int
    var placeholder: String?

    init(parent: MFQuestion, name: String, textType: MetaFormTextType, maxLength: Int? = 0, placeholder: String?) {
        self.textType = textType
        self.maxLength = maxLength ?? 0
        self.placeholder = placeholder
        super.init(parent: parent, controlType: MetaFormControlType.Html, name: name)
    }
}

class MFOptionControlBase: MFControl {
    var options: MFOptions
    var optionLayout: ControlLayoutStyle = ControlLayoutStyle.Vertical

    init(parent: MFQuestion, name: String, controlType: MetaFormControlType, options: MFOptions, optionLayout: ControlLayoutStyle) {
        self.options = options
        self.optionLayout = optionLayout
        super.init(parent: parent, controlType: controlType, name: name )
    }
    
    var hasOptionList: Bool
    {
        if let optionsList = self.options.list {
            return optionsList.count > 0
        }
        return false
    }
    
    var hasUrl: Bool {
        return self.options.optionSource != nil && self.options.optionSource?.url.count ?? 0 > 0
    }
    
    var optionList: [MFOptionValue] {
        return self.options.list ?? []
    }
    
    var optionUrl: String {
        return self.options.optionSource!.url
    }
}

class MFOptionControl: MFOptionControlBase {
    
}

class MFOptionMultiControl: MFOptionControlBase {
    
}

class MFDateControl: MFControl {
    var dateType: MetaFormDateType

    init(parent: MFQuestion, name: String, dateType: MetaFormDateType) {
        self.dateType = dateType
        super.init(parent: parent, controlType: MetaFormControlType.Date, name: name )
    }

    func getDay(form: MetaForm) -> String {
        return MFDateControl.getDayFrom(form.getValue(self.name))
    }

    
    func getMonth(form: MetaForm) -> String {
        return MFDateControl.getMonthFrom(form.getValue(self.name))
    }
    
    func getYear(form: MetaForm) -> String {
        return MFDateControl.getYearFrom(form.getValue(self.name))
    }
    
    func getMonthNames() -> [String] {
        return [
            "Month",
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December"
        ]
    }
    
    static func getDatePart(_ value: String) -> String {
        let parts = value.split(separator: " ")
        if parts.count == 2 {
            return String(parts[0])
        }
        return value
    }
    
    static func getDayFrom(_ value: String) -> String {
        if value.count > 5  {
            let parts = value.split(separator: "-")
            if parts.count > 2 {
                return String(parts[2])
            }
        }
        return ""
    }
    
    static func getMonthFrom(_ value: String) -> String {
        if value.count > 5  {
            let parts = value.split(separator: "-")
            if parts.count > 1 {
                return String(parts[1])
            }
        }
        return ""
    }
    
    static func getYearFrom(_ value: String) -> String {
        if value.count > 5  {
            let parts = value.split(separator: "-")
            if parts.count > 0 {
                return String(parts[0])
            }
        }
        return ""
    }
}

class MFTimeControl: MFControl {
    var hourStart: UInt8
    var hourEnd: UInt8
    var minuteStep: UInt8
    
    static func getTimePart(_ value: String) -> String {
        let parts = value.split(separator: " ")
        if parts.count == 2 {
            return String(parts[1])
        }
        return value
    }
    
    static func getHourPart(_ value: String) -> String {
        // Two options -
        // 1. the value is full date and time yyyy-mM-dD HH:MM
        // 2. the value is just a time HH:MM
        if value.count > 9 {
            // first format; split out on " " char to get just the time
            let parts = value.split(separator: " ")
            if parts.count == 2 {
                return hourPartFrom(time: String(parts[1]))
            }
        } else {
            return hourPartFrom(time: value)
        }
        
        return ""
    }
    
    static func getMinutePart(_ value: String) -> String {
        // Two options -
        // 1. the value is full date and time yyyy-mM-dD HH:MM
        // 2. the value is just a time HH:MM
        if value.count > 9 {
            // first format; split out on " " char to get just the time
            let parts = value.split(separator: " ")
            if parts.count == 2 {
                return minutePartFrom(time: String(parts[1]))
            }
        } else {
            return minutePartFrom(time: value)
        }
        
        return ""
    }
    
    private static func hourPartFrom(time: String) -> String {
        let timeParts = time.split(separator: ":")
        if timeParts.count == 2 {
            return String("0\(String(timeParts[0]))".suffix(2))
        }
        return ""
    }
    
    private static func minutePartFrom(time: String) -> String {
        let timeParts = time.split(separator: ":")
        if timeParts.count == 2 {
            return String(timeParts[1])
        }
        return ""
    }
    
    init(parent: MFQuestion, name: String, minuteStep: UInt8?, hourStart: UInt8?, hourEnd: UInt8?) {
        self.minuteStep = minuteStep ?? 1
        self.hourStart = hourStart ?? 0
        self.hourEnd = hourEnd ?? 23
        super.init(parent: parent, controlType: MetaFormControlType.Time, name: name)
    }

    func getHourList() -> [String] {
        var hourList: [String] = []
        
        for h in stride(from: self.hourStart, to: self.hourEnd, by: 1) {
            hourList.append(String("0\(h)".suffix(2)))
        }
        
        return hourList
    }

    func getMinuteList() -> [String] {
        var step = Int(self.minuteStep)
        var minuteList: [String] = []
        
        if step < 1 || step > 59 {
            step = 1
        }
        
        for m in stride(from: 0, to: 60, by: step) {
            minuteList.append(String("0\(m)".suffix(2)))
        }
        
        return minuteList
    }
}

struct MFOptions {
    var list: [MFOptionValue]?
    var optionSource: MFOptionSource?
    var emptyItem: String?
    var expandOptions: Bool = true
    
    static func OptionFromList(options: [MFOptionValue], emptyItem: String?, expandOptions: Bool = false) -> MFOptions{
        let o = MFOptions(list: options, emptyItem: emptyItem, expandOptions: expandOptions)
        return o;
    }

    static func OptionFromUrl(url: String, emptyItem: String?, expandOptions: Bool = false) -> MFOptions {
        let os = MFOptionSource(url: url)
        
        let o = MFOptions(list: nil, optionSource: os, emptyItem: emptyItem, expandOptions: expandOptions)

        return o;
    }    
}

struct MFOptionSource {
    var url: String
}

struct MFOptionValue {
    var code: String
    var description: String
}
