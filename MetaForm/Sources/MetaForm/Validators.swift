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
    
    var referencesField: String?
    
    init(type: String, message: String) {
        self.type = type
        self.message = message
    }
    
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        return true
    }
}

class MFValidatorAsync {
    
}
