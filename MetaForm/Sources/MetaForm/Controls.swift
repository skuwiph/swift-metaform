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
    
    func addLabel(_ label: String) -> MFControl {
        self.label = label
        return self
    }
    
    func addValidator(_ v: MFValidator) -> MFControl {
        if self.validators == nil {
            self.validators = []
        }
        
        self.validators!.append(v)
        
        if let references = v.referencesField {
            self.references = references
        }
        
        return self
    }
    
    func addValidatorAsync(_ v: MFValidatorAsync) -> MFControl {
        if self.validatorsAsync == nil {
            self.validatorsAsync = []
        }
        
        self.validatorsAsync!.append(v)
        
        if let references = v.referencesField {
            self.references = references
        }
        
        return self
    }
    
    func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        var valid = true
        
        if self.validators != nil {
            for v in self.validators! {
                if !v.isValid(form: form, control: self) {
                    valid = false
                    self.errorMessage = v.message
                    
                    NotificationCenter.default.post(name: Notification.Name.controlValidityDidChange, object: self, userInfo: ["data" : ControlValidityChanged(controlName: self.name, validator: v.type, isValid: valid)])
                    
                    break
                }
            }
        }
        
        return valid
    }
    
    func isValidAsync(form: MetaForm, updateStatus: Bool) {
        if self.validatorsAsync != nil {
            for v in self.validatorsAsync! {
                debugPrint("Validating \(v.type)")
                v.isValidAsync(form: form, control: self) { [weak self] valid, message in
                    if updateStatus {
                        self?.inError = !valid
                    }
                    self?.errorMessage = valid ? nil : message
                }
            }
        }
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
        super.init(parent: parent, controlType: .Label, name: name)
    }

    override func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        return true;
    }
}

class MFHtmlTextControl: MFControl {
    var html: String;

    init(parent: MFQuestion, name: String, html: String) {
        self.html = html
        super.init(parent: parent, controlType: .Html, name: name)
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
        super.init(parent: parent, controlType: .Html, name: name)
    }
}

class MFOptionControlBase: MFControl {
    var options: MFOptions
    var optionLayout: ControlLayoutStyle = .Vertical

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
    
    func checkDependencies() {
        // check options for referencing
        if !hasUrl {
            return
        }
        
        let r = urlFieldReferences()
        for referencedField in r {
            if dependencies == nil {
                dependencies = []
            }
            
            dependencies!.append(referencedField)
        }
    }
    
    func urlFieldReferences() -> [String] {
        var s = [String]()
        
        if hasUrl {
            let baseUrl = optionUrl
            let splits = baseUrl.split(separator: "/")
            if splits.count > 3 {
                for i in 3..<splits.endIndex {
                    let f = MetaForm.isFieldReference(value: String(splits[i]))
                    if f.isField {
                        s.append(f.fieldName!)
                    }
                }
            }
        }
        
        return s
    }
    
    func urlForService(form: MetaForm, control: MFControl) -> String? {
        if !hasUrl {
            return nil
        }
        
        let baseUrl = optionUrl
        if !baseUrl.contains("[") {
            return baseUrl
        }
        
        var url: String = ""
        let splits = baseUrl.split(separator: "/")
        if splits.count > 1 {
            url = "\(splits[0])//\(splits[1])/"
        }
        
        for i in 2..<splits.endIndex {
            let f = MetaForm.isFieldReference(value: String(splits[i]))
            if f.isField {
                let value = form.getValue(f.fieldName!)
                if !value.isEmpty {
                    url += "\(value)/"
                } else {
                    debugPrint("Value \(String(describing: f.fieldName)) wasn't found")
                    return nil
                }
            } else {
                url += "\(splits[i])/"
            }
        }
        
        if url.suffix(1) == "/" {
            return String(url[..<url.index(url.endIndex, offsetBy: -1)])
        }
        
        return url
    }
}

class MFOptionControl: MFOptionControlBase {
    
}

class MFOptionMultiControl: MFOptionControlBase {
    
}

protocol MFPDate {
    func getDay(form: MetaForm) -> String
    func getMonth(form: MetaForm) -> String
    func getYear(form: MetaForm) -> String
    func getMonthNames() -> [String]
}

class MFDateControl: MFControl, MFPDate {
    var dateType: MetaFormDateType

    init(parent: MFQuestion, name: String, dateType: MetaFormDateType) {
        self.dateType = dateType
        super.init(parent: parent, controlType: .Date, name: name )
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
        return value.split(with: " ", andTakePart: 0)
    }
    
    static func getDayFrom(_ value: String) -> String {
        if value.count > 5  {
            return value.split(with: "-", andTakePart: 2)
        }
        return ""
    }
    
    static func getMonthFrom(_ value: String) -> String {
        if value.count > 5  {
            return value.split(with: "-", andTakePart: 1)
        }
        return ""
    }
    
    static func getYearFrom(_ value: String) -> String {
        if value.count > 5  {
            return value.split(with: "-", andTakePart: 0)
        }
        return ""
    }
}

protocol MFPTime {
    func getHourList() -> [String]
    func getMinuteList() -> [String]
}

class MFTimeControl: MFControl, MFPTime {
    var hourStart: UInt8
    var hourEnd: UInt8
    var minuteStep: UInt8
    
    static func getTimePart(_ value: String) -> String {
        return value.split(with: " ", andTakePart: 1)
    }
    
    static func getHourPart(_ value: String) -> String {
        // Two options -
        // 1. the value is full date and time yyyy-mM-dD HH:MM
        // 2. the value is just a time HH:MM
        if value.count > 9 {
            // first format; split out on " " char to get just the time
            return hourPartFrom(time: value.split(with: " ", andTakePart: 1))
        } else {
            return hourPartFrom(time: value)
        }
    }
    
    static func getMinutePart(_ value: String) -> String {
        // Two options -
        // 1. the value is full date and time yyyy-mM-dD HH:MM
        // 2. the value is just a time HH:MM
        if value.count > 9 {
            // first format; split out on " " char to get just the time
            return minutePartFrom(time: value.split(with: " ", andTakePart: 1))
        } else {
            return minutePartFrom(time: value)
        }
    }
    
    private static func hourPartFrom(time: String) -> String {
        let hour = time.split(with: ":", andTakePart: 0)
        return String("0\(hour)".suffix(2))
    }
    
    private static func minutePartFrom(time: String) -> String {
        return time.split(with: ":", andTakePart: 1)
    }
    
    init(parent: MFQuestion, name: String, minuteStep: UInt8?, hourStart: UInt8?, hourEnd: UInt8?) {
        self.minuteStep = minuteStep ?? 1
        self.hourStart = hourStart ?? 0
        self.hourEnd = hourEnd ?? 23
        super.init(parent: parent, controlType: .Time, name: name)
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

class MFDateTimeControl: MFControl, MFPTime, MFPDate {
    var dateControl: MFDateControl
    var timeControl: MFTimeControl
    
    init(parent: MFQuestion, name: String, minuteStep: UInt8?, hourStart: UInt8?, hourEnd: UInt8?) {
        self.dateControl = MFDateControl(parent: parent, name: "\(name)_date", dateType: .Full)
        self.timeControl = MFTimeControl(parent: parent, name: "\(name)_time", minuteStep: minuteStep, hourStart: hourStart, hourEnd: hourEnd)
        super.init(parent: parent, controlType: .DateTime, name: name)
    }
    
    func getHourList() -> [String] {
        return self.timeControl.getHourList()
    }
    
    func getMinuteList() -> [String] {
        return self.timeControl.getMinuteList()
    }
    
    func getDay(form: MetaForm) -> String {
        return self.dateControl.getDay(form: form)
    }
    
    func getMonth(form: MetaForm) -> String{
        return self.dateControl.getMonth(form: form)
    }
    
    func getYear(form: MetaForm) -> String{
        return self.dateControl.getYear(form: form)
    }
    
    func getMonthNames() -> [String]{
        return self.dateControl.getMonthNames()
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

class MFTelephoneAndIddControl: MFControl {
    var maxLength: Int = 0
    var placeholder: String?
    var iddList: [IddCode] = []
    
    init(parent: MFQuestion, name: String, maxLength: Int? = 0, placeholder: String? = "") {
        self.placeholder = placeholder
        self.maxLength = maxLength ?? 0
        super.init(parent: parent, controlType: .TelephoneAndIddCode, name: name)
    }
    
    func getIdd(form: MetaForm) -> String {
        let value = form.getValue(self.name)
        return value.split(with: ":", andTakePart: 0)
    }
    
    func getNumber(form: MetaForm) -> String {
        let value = form.getValue(self.name)
        return value.split(with: ":", andTakePart: 1)
    }
}

struct IddCode {
    var code: String
    var name: String
}

class MFToggleControl: MFControl {
    var text: String?
    init(parent: MFQuestion, name: String, text: String? ) {
        self.text = text
        super.init(parent: parent, controlType: .Toggle, name: name)
    }
}

class MFSliderControl: MFControl {
    var text: String
    var min: Int
    var max: Int
    var step: Int
    
    init(parent: MFQuestion, name: String, min: Int, max: Int, step: Int, text: String?) {
        self.text = text ?? ""
        self.min = min
        self.max = max
        self.step = step
        super.init(parent: parent, controlType: .Slider, name: name)
    }
}
