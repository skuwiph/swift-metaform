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
            return answers.getValue(f.fieldName!)
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

// Implementations of MFValidator

class MFValueRequired: MFValidator {
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = false

        // Does the control have a value?
        if form.getValue(control.name).count > 0 {
            valid = true
        }

        // Interesting edge case - if this is an option-based
        // control, but we have no options, we assume that the question
        // cannot be displayed and should pass this validator
        if control.controlType == MetaFormControlType.Option {
            let opt = control as! MFOptionControl;
            if (!opt.hasOptionList) {
                valid = true
            }
        }

        return valid
    }
}

class MFAnswerMustMatch: MFValidator {
    var value: String
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }

    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = false;

        // the value for 'match' must equal the value
        // stored in the answers for this control
        let answerToCheck = form.getValue(control.name)
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value)

        valid = answerToCheck == matchingValue;

        return valid;
    }
}

class MFEmailValidator: MFValidator {
    // Validates according to the AngularJS Email Validator Regular Expression
    // See: https://github.com/ODAVING/angular/commit/10c9f4cb2016fc070bc7626d2736d9c5b9166989
    // For clarification
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        let pattern = "/^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$/"
        
        var valid = true
        let value = form.getValue(control.name)
        if value.count > 0 {
            let validator = NSPredicate(format:"SELF MATCHES[c] %@", pattern)
            valid = validator.evaluate(with: value)
        }
        return valid;
    }
}

// Date validation
// NOTE(Ian) -> Must check locale/timezone changes.
// The date control tries to maintain a safe internal format
// but converting to an actual Date time for validation
// may cause issues.
class MFDateValidator: MFValidator {
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = true;

        let value = form.getValue(control.name);
        if value.count > 0 {
            let date = form.data.getValueAsDate(control.name)

            valid = date != nil
        }
        return valid;
    }
}

class MFDateTimeValidator: MFValidator {
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = true;

        let value = form.getValue(control.name);
        if !value.isEmpty {
            let date = form.data.getValueAsDateTime(control.name);

            valid = date != nil;
        }
        return valid;
    }
}

class MFDateMustBeAfterValidator: MFValidator {
    var value: String;
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }
    
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value);

        if !answerToCheck.isEmpty {
            let date = form.data.getValueAsDate(control.name);
            let minDate = form.data.convertValueToDate(matchingValue);

            if date == nil || minDate == nil {
                return valid
            }
            valid = date! > minDate!;
        }
        return valid;
    }
}

class MFDateMustBeBeforeValidator: MFValidator {
    var value: String;
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }
    
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value);

        if !answerToCheck.isEmpty {
            let date = form.data.getValueAsDate(control.name);
            let maxDate = form.data.convertValueToDate(matchingValue, timeValue: nil);

            if date == nil || maxDate == nil {
                return valid
            }
            valid = date! < maxDate!;
        }
        return valid;
    }
}

class MFMustBeBetweenValidator: MFValidator {
    var min: String;
    var max: String;
    
    init(type: String, message: String, min: String, max: String) {
        self.min = min
        self.max = max
        super.init(type: type, message: message)
    }

    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name);
        if !answerToCheck.isEmpty {

            let minCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.min);
            let maxCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.max);

            if (control.controlType == MetaFormControlType.Date || control.controlType == MetaFormControlType.Time) {
                valid = self.dateInRange(form: form, check: answerToCheck, after: minCheck, before: maxCheck);
            } else {
                valid = false;
                //valid = +answerToCheck > +minCheck && +answerToCheck < +maxCheck;
            }
        }
        return valid;
    }

    private func dateInRange(form: MetaForm, check: String, after: String, before: String) -> Bool {
        var valid = true;

        let checkDate = form.data.convertValueToDate(check, timeValue: nil);
        let minDate = form.data.convertValueToDate(after, timeValue: nil);
        let maxDate = form.data.convertValueToDate(before, timeValue: nil);

        if checkDate == nil || minDate == nil || maxDate == nil {
            return valid
        }
        
        valid = checkDate! > minDate! && checkDate! < maxDate!;

        return valid;
    }
}

class MFMustExceedWordCountValidator: MFValidator {
    var targetWordCount: Int;
    
    init(type: String, message: String, targetWordCount: Int) {
        self.targetWordCount = targetWordCount
        super.init(type: type, message: message)
    }
    
    override func isValid(form: MetaForm, control: MFControl) -> Bool {
        var valid = false;

        let answerToCheck = form.getValue(control.name);
//        if (answerToCheck) {
//            var wordCount = answerToCheck
//                .replace(/\./g, ': ')
//                .replace(/\S+/g, 'a')
//                .replace(/\s+/g, '').count;
//
//            valid = wordCount >= this.targetWordCount;
//        }

        return valid;
    }
}
