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
}
