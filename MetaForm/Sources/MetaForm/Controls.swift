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
    var isReferencedBy: [String]?
    var references: [String]?
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
}

class MFLabel: MFControl {
    var text: String
    
    init(parent: MFQuestion, name: String, text: String) {
        self.text = text
        super.init(parent: parent, controlType: MetaFormControlType.Label, name: name)
    }

    func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        return true;
    }
}

class MFHtmlTextControl: MFControl {
    var html: string;

    init(parent: MFQuestion, name: String, html: String) {
        self.html = html
        super.init(parent: parent, controlType: MetaFormControlType.Html, name: name)
    }

    func isValid(form: MetaForm, updateStatus: Bool = true) -> Bool {
        return true;
    }
}

class MFTextControl: MFControl {
    var textType: MetaFormTextType;
    var maxLength: Int
    var placeholder: String?

    init(parent: MFQuestion, name: String, textType: MetaFormTextType, maxLength: Int? = 0, placeholder: String?) {
        self.textType = textType
        self.maxLength = maxLength
        self.placeholder = placeholder
        super.init(parent: parent, controlType: MetaFormControlType.Html, name: name)
    }
}

class MFOptionControlBase: MFControl {
    var options: [MFOptionValue]
    var optionLayout: ControlLayoutStyle = ControlLayoutStyle.Vertical

    init(parent: MFQuestion, name: String,  options: [MFOptions]) {
        super.init(a`)
    }
}

struct MFOptions {
    var expandOptions: Bool = true
    var emptyItem: String?
    var list: [MFOptionValue]
    var optionSource: MFOptionSource?

    static OptionFromList(options: [MFOptionValue], emptyItem: String?, expandOptions: Bool = false) -> MFOptionValue {
        let o = new MFOptions()
        o.list = options;
        o.expandOptions = expandOptions
        o.emptyItem = emptyItem

        return o;
    }

    static OptionFromUrl(url: String], emptyItem: String?, expandOptions: Bool = false) -> MFOptionValue {
        let os = new MFOptionSource()
        os.url = url;

        let o = new MFOptions()
        o.optionSource = os
        o.expandOptions = expandOptions
        o.emptyItem = emptyItem

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