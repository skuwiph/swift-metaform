//
//  Validators.swift
//  
//
//  Created by Ian Seckington on 09/03/2020.
//

import Foundation

class MFValidator {
    var type: String
    var message: String
    
    var referencesField: [String]?
    
    init(type: String, message: String) {
        self.type = type
        self.message = message
    }
    
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        return true
    }
    
    func checkForReference(value: String) {
        let check = MetaForm.isFieldReference(value: value)
        if check.isField {
            if self.referencesField == nil {
                self.referencesField = []
            }
            
            self.referencesField?.append(check.fieldName!)
        }
    }
    
    func getAnswerForControl(answers: MetaFormData, valueToCheck: String) -> String {
        let f = MetaForm.isFieldReference(value: valueToCheck)
        let v = MetaForm.isVariableReference(value: valueToCheck)
        
        if f.isField {
            return answers.getValue(name: f.fieldName!)
        } else if v.isVariable {
            return MFValidator.resolve(variable: v.variableName!)
        } else {
            return valueToCheck
        }
    }
    
    static func resolve(variable: String) -> String {
        return ""
    }
}

class MFValidatorAsync {
    
}
