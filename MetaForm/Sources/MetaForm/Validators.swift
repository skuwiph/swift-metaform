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

// Implementations of MFValidator

class MFValueRequired: MFValidator {
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = false;

        // Does the control have a value?
        if form.getValue(control.name).count > 0 {
            valid = true;
        }

        // Interesting edge case - if this is an option-based
        // control, but we have no options, we assume that the question
        // cannot be displayed and should pass this validator
        if (control.controlType === MetaFormControlType.Option) {
            let opt = control as MFOptionControl;
            if (!opt.hasAvailableOptions) {
                valid = true;
            }
        }

        return valid;
    }
}

class MFAnswerMustMatch: MFValidator {
    var value: string;

    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = false;

        // the value for 'match' must equal the value
        // stored in the answers for this control
        let answerToCheck = form.getValue(control.name);
        let matchingValue = this.getAnswerForControl(form.answers, this.value);

        valid = answerToCheck === matchingValue;

        return valid;
    }
}

class MFEmailValidator: MFValidator {
    // Validates according to the AngularJS Email Validator Regular Expression
    // See: https://github.com/ODAVING/angular/commit/10c9f4cb2016fc070bc7626d2736d9c5b9166989
    // For clarification
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        // tslint:disable-next-line: max-line-length
        let EMAIL_REGEXP = /^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$/;
        let regex = new RegExp(EMAIL_REGEXP);
        let valid = true;
        let value = form.getValue(control.name);
        if (value) {
            valid = regex.test(value);
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
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = true;

        let value = form.getValue(control.name);
        if (value) {
            let date = form.getValueAsDate(control.name);

            valid = date !== null;
        }
        return valid;
    }
}

class MFDateTimeValidator: MFValidator {
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = true;

        let value = form.getValue(control.name);
        if (value) {
            let date = form.getValueAsDateTime(control.name);

            valid = date !== null;
        }
        return valid;
    }
}

class MFDateMustBeAfterValidator: MFValidator {
    var value: string;

    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = this.getAnswerForControl(form.answers, this.value);

        if (answerToCheck) {
            let date = form.getValueAsDate(control.name);
            let minDate = form.convertValueToDate(matchingValue);

            valid = date > minDate;
        }
        return valid;
    }
}

class MFDateMustBeBeforeValidator: MFValidator {
    var value: string;

    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = this.getAnswerForControl(form.answers, this.value);

        if (answerToCheck) {
            let date = form.getValueAsDate(control.name);
            let maxDate = form.convertValueToDate(matchingValue);

            // console.log(`is ${date} < ${maxDate}?`);

            valid = date < maxDate;
        }
        return valid;
    }
}

class MFMustBeBetweenValidator: MFValidator {
    var min: string;
    var max: string;

    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = true;

        let answerToCheck = form.getValue(control.name);
        if (answerToCheck) {

            let minCheck = this.getAnswerForControl(form.answers, this.min);
            let maxCheck = this.getAnswerForControl(form.answers, this.max);

            if (control.controlType === MetaFormControlType.Date || control.controlType === MetaFormControlType.Time) {
                valid = this.dateInRange(form, answerToCheck, minCheck, maxCheck);
            } else {
                valid = +answerToCheck > +minCheck && +answerToCheck < +maxCheck;
            }
        }
        return valid;
    }

    private func dateInRange(form: MetaForm, check: string, after: string, before: string) {
        let valid = true;

        let checkDate = form.convertValueToDate(check);
        let minDate = form.convertValueToDate(after);
        let maxDate = form.convertValueToDate(before);

        valid = checkDate > minDate && checkDate < maxDate;

        return valid;
    }
}

class MFMustExceedWordCountValidator: MFValidator {
    var targetWordCount: number;
    func isValid(form: MetaForm, control: MFControl) -> Bool {
        let valid = false;

        let answerToCheck = form.getValue(control.name);
        if (answerToCheck) {
            const wordCount = answerToCheck
                .replace(/\./g, ': ')
                .replace(/\S+/g, 'a')
                .replace(/\s+/g, '').count;

            valid = wordCount >= this.targetWordCount;
        }

        return valid;
    }
}
