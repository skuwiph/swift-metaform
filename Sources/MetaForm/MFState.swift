//
//  MFState.swift
//
//  Describes the state required for the metaform
//
//  Created by Ian Seckington on 30/04/2020.
//

import SwiftUI
import Combine

@available(OSX 10.15, *)
@available(iOS 13, *)
public class MetaFormState: ObservableObject {
    @Published var data: Dictionary<String, String> = [:]
    @Published var displayQuestions: [MFQuestion] = []
    
    @Published var validity: Dictionary<String, Bool> = [:]
    @Published var errors: Dictionary<String, String> = [:]
    
    var form: MFForm
    var rules: BusinessRules
    var lastDisplayedItem = -1
    
    public var atStartOfQuestions = false
    public var atEndOfQuestions = false
    
//    var controls: Dictionary<String, MFControl> = [:]
    
    public init(form: MFForm, rules: BusinessRules?) {
        self.form = form
        self.rules = rules ?? BusinessRules()
    }
    
    public func getQuestionsToDisplay(forwards: Bool = true) {
        var dq: DisplayQuestions;
        
        if forwards {
         dq = MetaFormService.shared.getNextQuestionToDisplay(form: self.form, rules: self.rules, last: lastDisplayedItem)
        } else {
            dq = MetaFormService.shared.getPreviousQuestionToDisplay(form: self.form, rules: self.rules, last: lastDisplayedItem)
        }
                
        self.atStartOfQuestions = dq.atStart
        self.atEndOfQuestions = dq.atEnd
        self.lastDisplayedItem = dq.lastItem

        // Reset displayed questions array
        self.displayQuestions.removeAll()
        self.displayQuestions.append(contentsOf: dq.questions)

        self.data.removeAll()
        self.errors.removeAll()
        self.validity.removeAll()
        
        // So, we have some questions! But we need to get the data
        // items out for each question and set up the control status values
        for q in dq.questions {
            for c in q.controls {
                data[c.name] = self.form.getValue(c.name)
                let r = form.checkValidity(c.name)
                validity[c.name] = r.isValid
            }
        }
    }
    
    public func bindingFor(for key: String) -> Binding<String> {
        return Binding(get: {
            return self.data[key] ?? ""
        }, set: {
            self.data[key] = $0
            
            // NOTE: Not sure if I really want to duplicate the
            // data in the form, but it does mean that the form
            // has it's own data sink for validation and testing
            // as well as the smaller subset we are surfacing
            // for the current display
            self.form.setValue(key, value: $0)
            self.validate(key)
        })
    }
    
    public func errorFor(for key: String) -> Binding<String> {
        return Binding(get: {
            return self.errors[key] ?? ""
        }, set: {
            self.errors[key] = $0
        })
    }
    
    func validate(_ name: String) {
        let result = form.checkValidity(name)
        self.validity[name] = result.isValid
        self.errors[name] = result.message
    }
}
