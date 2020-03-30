//
//  Validators.swift
//  
//
//  Created by Ian Seckington on 09/03/2020.
//

import Foundation

typealias AsyncValidationResult = ( Bool, String ) -> Void

public class MFValidator {
    var type: String
    var message: String
    
    var referencesField: [String]?
    
    init(type: String, message: String) {
        self.type = type
        self.message = message
    }
    
    public func isValid(form: MFForm, control: MFControl) -> Bool {
        return true
    }
    
    func isValidAsync(form: MFForm, control: MFControl, completion: @escaping AsyncValidationResult) {
    
    }
    
    func checkForReference(value: String) {
        let check = MFForm.isFieldReference(value: value)
        if check.isField {
            if self.referencesField == nil {
                self.referencesField = []
            }
            
            self.referencesField?.append(check.fieldName!)
        }
    }
    
    func getAnswerForControl(answers: MetaFormData, valueToCheck: String) -> String {
        let f = MFForm.isFieldReference(value: valueToCheck)
        let v = MFForm.isVariableReference(value: valueToCheck)
        
        if f.isField {
            return answers.getValue(f.fieldName!)
        } else if v.isVariable {
            return MFValidator.resolve(variable: v.variableName!)
        } else {
            return valueToCheck
        }
    }
    
    public static func Required(message: String) -> MFValueRequired {
        let v = MFValueRequired(type: "Required", message: message)
        return v;
    }
    
    public static func AnswerMustMatch(_ match: String, message: String) -> MFAnswerMustMatch {
        let v = MFAnswerMustMatch(type: "AnswerMustMatch", message: message, value: match)
        return v
    }
    
    public static func Email(message: String) -> MFEmailValidator {
        let v = MFEmailValidator(type: "Email", message: message)
        return v
    }
    
    public static func Date(message: String) -> MFDateValidator {
        let v = MFDateValidator(type: "Date", message: message)
        return v
    }
    
    public static func DateTime(message: String) -> MFDateTimeValidator {
        let v = MFDateTimeValidator(type: "DateTime", message: message)
        return v
    }
    
    public static func DateMustBeAfter(_ min: String, message: String) -> MFDateMustBeAfterValidator {
        let v = MFDateMustBeAfterValidator(type: "MustBeAfter", message: message, value: min)
        return v
    }
    
    public static func DateMustBeBefore(_ max: String, message: String) -> MFDateMustBeBeforeValidator {
        let v = MFDateMustBeBeforeValidator(type: "MustBeBefore", message: message, value: max)
        return v
    }
    
    public static func MustBeBetween(after: String, before: String, message: String) -> MFMustBeBetweenValidator {
        let v = MFMustBeBetweenValidator(type: "MustBeBetween", message: message, min: after, max: before)
        return v
    }
    
    public static func MinimumWordCount(_ count: Int, message: String) -> MFMustExceedWordCountValidator {
        let v = MFMustExceedWordCountValidator(type: "MinimumWordCount", message: message, targetWordCount: count)
        return v
    }
    
    static func resolve(variable: String) -> String {
        return ""
    }
}

public class MFValidatorAsync: MFValidator {
    var url: String
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    init(type: String, message: String, url: String) {
        self.url = url
        super.init(type: type, message: message)
    }
    
    override func isValidAsync(form: MFForm, control: MFControl, completion: @escaping AsyncValidationResult) {
        debugPrint("isValidAsync")
        
        dataTask?.cancel()
    
        guard let serviceUrl = URL(string: url) else {
            debugPrint("Failure at step 1")
            return
        }
        
        let params = ["check": form.getValue(control.name)]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/JSON", forHTTPHeaderField: "Content-Type")
        guard let body = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            debugPrint("Failure at step 2")
            return
        }
        
        request.httpBody = body
        
        debugPrint("Request: \(request)")
        
        dataTask = defaultSession.dataTask(with: request) { data, response, error in
            defer {
                self.dataTask = nil
            }
            
            guard let data = data else {
                if let error = error {
                    debugPrint("Failed at step 3: error: \(error.localizedDescription)")
                } else {
                    debugPrint("Failed at step 3 with no error")
                }
                return
            }
            
            do {
                let data = try JSONDecoder().decode(MFAsyncValidationResponse.self, from: data)
                DispatchQueue.main.async {
                    debugPrint("got data from \(self.url): \(data)")
                    completion( data.valid, self.message)
                }
            } catch let error {
                debugPrint(error.localizedDescription)
            }
        }
        dataTask?.resume()
    }
    
    static func AsyncValidator(url: String, message: String) -> MFValidatorAsync {
        let v = MFValidatorAsync(type: "Async", message: message, url: url)
        return v
    }
}

public struct MFAsyncValidationResponse: Codable {
    var valid: Bool
}

// Implementations of MFValidator

public class MFValueRequired: MFValidator {
    override public func isValid(form: MFForm, control: MFControl) -> Bool {
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

public class MFAnswerMustMatch: MFValidator {
    var value: String
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }

    override public func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = false;

        // the value for 'match' must equal the value
        // stored in the answers for this control
        let answerToCheck = form.getValue(control.name)
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value)

        valid = answerToCheck == matchingValue;

        return valid;
    }
}

public class MFEmailValidator: MFValidator {
    // Validates according to the AngularJS Email Validator Regular Expression
    // See: https://github.com/ODAVING/angular/commit/10c9f4cb2016fc070bc7626d2736d9c5b9166989
    // For clarification
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        let pattern = "(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"
            + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
            + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
            + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
            + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
            + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
            + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
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
public class MFDateValidator: MFValidator {
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = true;

        let value = form.getValue(control.name);
        if value.count > 0 {
            let date = form.data.getValueAsDate(control.name)

            valid = date != nil
        }
        return valid;
    }
}

public class MFDateTimeValidator: MFValidator {
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = true;

        let value = form.getValue(control.name);
        if !value.isEmpty {
            let date = form.data.getValueAsDateTime(control.name);

            valid = date != nil;
        }
        return valid;
    }
}

public class MFDateMustBeAfterValidator: MFValidator {
    var value: String;
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }
    
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value);

        if !answerToCheck.isEmpty {
            let date = form.data.getValueAsDate(control.name);
            let minDate = form.data.convertValueToDate(matchingValue);

            if date == nil || minDate == nil {
                valid = false
            } else {
                valid = date! > minDate!;
            }
        }
        return valid;
    }
}

public class MFDateMustBeBeforeValidator: MFValidator {
    var value: String;
    
    init(type: String, message: String, value: String) {
        self.value = value
        super.init(type: type, message: message)
    }
    
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name);
        let matchingValue = self.getAnswerForControl(answers: form.data, valueToCheck: self.value);

        if !answerToCheck.isEmpty {
            let date = form.data.getValueAsDate(control.name);
            let maxDate = form.data.convertValueToDate(matchingValue, timeValue: nil);

            if date == nil || maxDate == nil {
                valid = false
            } else {
                valid = date! < maxDate!;
            }
        }
        return valid;
    }
}

public class MFMustBeBetweenValidator: MFValidator {
    var min: String;
    var max: String;
    
    init(type: String, message: String, min: String, max: String) {
        self.min = min
        self.max = max
        super.init(type: type, message: message)
    }

    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = true;

        let answerToCheck = form.getValue(control.name)
        if !answerToCheck.isEmpty {
            if (control.controlType == .Date
                || control.controlType == .Time
                || control.controlType == .DateTime) {
                valid = self.dateInRange(form: form, control: control)
            } else {
                valid = self.numericInRange(form: form, answerToCheck: answerToCheck)
            }
        }
        return valid
    }

    private func dateInRange(form: MFForm, control: MFControl) -> Bool {
        var valid = true;
        let minCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.min)
        let maxCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.max)

        let checkDate = form.data.getValueAsDateTime(control.name)
        let minDate = form.data.getAsDateTime(minCheck)
        let maxDate = form.data.getAsDateTime(maxCheck)

        if checkDate == nil || minDate == nil || maxDate == nil {
            return valid
        }
        
        valid = checkDate! > minDate! && checkDate! < maxDate!;

        return valid;
    }
    
    private func numericInRange(form: MFForm, answerToCheck: String) -> Bool {
        var valid = true;
        
        let minCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.min)
        let maxCheck = self.getAnswerForControl(answers: form.data, valueToCheck: self.max)

        guard let check = Int(answerToCheck),
            let min = Int(minCheck),
            let max = Int(maxCheck) else {
                return false
        }
        
        valid = check > min && check < max;
        
        return valid;
    }
}

public class MFMustExceedWordCountValidator: MFValidator {
    var targetWordCount: Int;
    
    init(type: String, message: String, targetWordCount: Int) {
        self.targetWordCount = targetWordCount
        super.init(type: type, message: message)
    }
    
    public override func isValid(form: MFForm, control: MFControl) -> Bool {
        var valid = false;

        let answerToCheck = form.getValue(control.name);
        if answerToCheck.count > 0  {
            valid = answerToCheck.numberOfWords >= self.targetWordCount
       }

        return valid;
    }
}
