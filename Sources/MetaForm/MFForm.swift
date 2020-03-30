import Foundation

public class MFForm {
    var name: String
    var title: String
    var version = 1
    var dateModified = Date()
    var dataSource: String?
    var drawType: MetaFormDrawType = .SingleQuestion
    var allowSaves: Bool = false
    var sections: [MFSection] = []
    var questions: [MFQuestion] = []
    var data = MetaFormData()
    
    var rules: BusinessRules?
    
    public init(name: String, title: String, drawType: MetaFormDrawType? = nil) {
        self.name = name
        self.title = title
        self.drawType = drawType ?? .SingleQuestion
    }
    
    // Initialise the form ready for first use/display
    public func initialise() {
        // Find all field references and dependencies
        for q in self.questions {
            for c in q.controls {
                // a reference is required when a validator
                // from one control checks against another
                // control
                if !c.references.isEmpty {
                    for name in c.references {
                        self.addReference(from: c.name, to: name)
                    }
                }
                
                // A dependency is where data has to come
                // from another control
                if c.dependencies != nil && !c.dependencies!.isEmpty {
                    for dependent in c.dependencies! {
                        self.addReference(from: c.name, to: dependent)
                    }
                }
                
                self.determineQuestionDisplay(question: q, dependencies: c.dependencies)
            }
        }
    }
    
    public func isValid(_ updateStatus: Bool = true) -> Bool {
        return self.areQuestionsValid(self.questions, updateStatus: updateStatus)
    }
    
    public func areQuestionsValid(_ questions: [MFQuestion], updateStatus: Bool = true) -> Bool {
        var valid = true
        
        for q in questions {
            if self.ruleMatches(q, rules: self.rules) {
                if !q.isValid(self, updateStatus: updateStatus) {
                    valid = false
                    break;
                }
            }
        }
        
        return valid
    }
    
    public func ruleMatches(_ question: MFQuestion, rules: BusinessRules?) -> Bool {
        if self.drawType == .SingleQuestion || question.ruleToMatch == nil || rules == nil {
            return true
        }
        
        return rules!.evaluateRule(question.ruleToMatch!, data: self.data)
    }
    
    public func determineQuestionDisplay(question: MFQuestion, dependencies: [String]?) {
        if dependencies == nil {
            return
        }
        
        question.canBeDisplayed = {
            for c in question.controls {
                if c.dependencies != nil {
                    for d in c.dependencies! {
                        return self.getValue(d).isEmpty
                    }
                }
            }
            
            return true
        }
    }
    
    public func getValue(_ name: String) -> String {
        return self.data.getValue(name)
    }
    
    public func setValue(_ name: String, value: String) {
        self.data.setValue(name, value: value)
    }
    
    public func addQuestion(name: String, caption: String) -> MFQuestion {
        let q = MFQuestion(sectionId: 1, name: name, caption: caption)
        self.questions.append(q)
        
        return q;
    }
    
    public func getQuestion(name: String) -> MFQuestion? {
        if let q = self.questions.first(where: { $0.name == name}) {
            return q
        }
        
        return nil
    }
    
    private func addReference(from: String, to: String) {
        if let toControl = self.getControlBy(name: to) {
            toControl.addReferencedBy(controlName: from)
        }
    }
    
    private func getControlBy(name: String) -> MFControl? {
        for q in self.questions {
            for c in q.controls {
                if c.name == name {
                    return c
                }
            }
        }
        return nil
    }
    
    public static func createSimpleFormWith(name: String, title: String) -> MFForm {
        let f = MFForm(name: name, title: title, drawType: .SingleQuestion)
        return f
    }
    
    static func isFieldReference(value: String) -> (isField: Bool, fieldName: String?) {
        if value.contains("[") {
            return ( isField: true, fieldName: getFieldName(from: value))
        }
        return (isField: false, fieldName: nil)
    }
    
    static func isVariableReference(value: String) -> (isVariable: Bool, variableName: String?) {
        if value.contains("%") {
            return ( isVariable: true, variableName: getVariable(from: value))
        }
        return (isVariable: false, variableName: nil)
    }
    
    static func getFieldName(from: String) -> String {
        let start = from.index(from.startIndex, offsetBy: 1)
        let end = from.index(from.endIndex, offsetBy: -1)
        let range = start..<end
        return String(from[range])
    }
    
    static func getVariable(from: String) -> String {
        let start = from.index(from.startIndex, offsetBy: 1)
        let range = start..<from.endIndex
        return String(from[range])
    }
}

public struct MFSection {
    var id: Int
    var title: String
    var ruleToMatch: String?
}

public class MFQuestion {
    var sectionId: Int
    var name: String
    var caption: String?
    var captionFootnote: String?
    var ruleToMatch: String?
    var controlLayout: ControlLayoutStyle = ControlLayoutStyle.Vertical
    var controls: [MFControl] = []
    var readonly = false
    var available = true
    var canBeDisplayed: () -> Bool = {return true}
    
    init(sectionId: Int, name: String, caption: String?) {
        self.sectionId = sectionId
        self.name = name
        self.caption = caption
    }
    
    func isValid(_ form: MFForm, updateStatus: Bool) -> Bool {
        var valid = true
        
        for c in self.controls {
            if !c.isValid(form: form, updateStatus: updateStatus) {
                valid = false
            }
        }
        
        return valid
    }
    
    public func addTextControl(name: String, textType: MetaFormTextType, maxLength: Int? = 0, placeholder: String? = "") -> MFTextControl {
        let t = MFTextControl(parent: self, name: name, textType: textType, maxLength: maxLength, placeholder: placeholder)
        self.pushControl(control: t)
        return t
    }
    
    public func addDateControl(name: String, dateType: MetaFormDateType) -> MFDateControl {
        let c = MFDateControl(parent: self, name: name, dateType: dateType)
        self.pushControl(control: c)
        
        return c
    }
    
    public func addTimeControl(name: String, minuteStep: UInt8?, hourStart: UInt8?, hourEnd: UInt8?) -> MFTimeControl {
        let c = MFTimeControl(parent: self, name: name, minuteStep: 15, hourStart: 8, hourEnd: 20)
        
        self.pushControl(control: c)
        
        return c
    }
    
    public func addDateTimeControl(name: String, minuteStep: UInt8?, hourStart: UInt8?, hourEnd: UInt8?) -> MFDateTimeControl {
        let c = MFDateTimeControl(parent: self, name: name, minuteStep: 15, hourStart: 8, hourEnd: 20)
        
        self.pushControl(control: c)
        return c
    }
    
    public func addOptionControl(name: String, options: MFOptions, layout: ControlLayoutStyle = ControlLayoutStyle.Vertical) -> MFOptionControl {
        let c = MFOptionControl(parent: self, name: name, controlType: MetaFormControlType.Option, options: options, optionLayout: layout)
        c.checkDependencies()
        self.pushControl(control: c)
        
        return c
    }
    
    public func addOptionMultiControl(name: String, options: MFOptions, layout: ControlLayoutStyle = ControlLayoutStyle.Vertical) -> MFOptionMultiControl {
        let c = MFOptionMultiControl(parent: self, name: name, controlType: MetaFormControlType.OptionMulti, options: options, optionLayout: layout)
        c.checkDependencies()

        self.pushControl(control: c)
        
        return c
    }
    
    public func addTelephoneAndIddCode(name: String, maxLength: Int? = nil, placeholder: String? = nil) -> MFTelephoneAndIddControl {
        let c = MFTelephoneAndIddControl(parent: self, name: name, maxLength: maxLength, placeholder: placeholder)
        self.pushControl(control: c)
        return c
    }
    
    public func addToggleControl(name: String, text: String? = nil) -> MFToggleControl {
        let c = MFToggleControl(parent: self, name: name, text: text)
        self.pushControl(control: c)
        return c
    }
    
    public func addSliderControl(name: String, text: String? = nil, min: Int, max: Int, step: Int) -> MFSliderControl {
        let c = MFSliderControl(parent: self, name: name, min: min, max: max, step: step, text: text)
        self.pushControl(control: c)
        return c
    }
    
    public func setSection(_ id: Int) -> MFQuestion {
        self.sectionId = id
        return self
    }
    
    public func setDisplayRule(_ rule: String) -> MFQuestion {
        self.ruleToMatch = rule
        return self
    }
    
    private func pushControl(control: MFControl) {
        
        self.controls.append(control)
    }
}

public struct MFAnimation {
    var event: String
    var name: String
}

