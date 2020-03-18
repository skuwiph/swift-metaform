//
//  MetaFormService.swift
//  
//
//  Created by Ian Seckington on 18/03/2020.
//

import Foundation

public struct MetaFormService {
    static let shared = MetaFormService()
    private init() { }
    
    func getNextQuestionToDisplay(form: MFForm, rules: BusinessRules, last: Int) -> DisplayQuestions {
        return getDisplayQuestions(form: form, rules: rules, last: last, direction: 1)
    }
    
    func getPreviousQuestionToDisplay(form: MFForm, rules: BusinessRules, last: Int) -> DisplayQuestions {
        return getDisplayQuestions(form: form, rules: rules, last: last, direction: -1)
    }

    private func getDisplayQuestions(form: MFForm, rules: BusinessRules, last: Int, direction: Int) -> DisplayQuestions {
        if form.questions.count == 0 {
            debugPrint("No questions in this form!")
            return DisplayQuestions(questions: [], atEnd: true, atStart: true, numberOfControls: 0, lastItem: 0)
        }
        
        switch form.drawType {
        case .SingleQuestion:
            return getSingleQuestion(form: form, rules: rules, lastQuestion: last, direction: direction)
        case .EntireSection:
            return getQuestionsInSection(form: form, rules: rules, lastSection: last, direction: direction)
        case .EntireForm:
            return getQuestionsInForm(form)
        }
    }
    
    private func getSingleQuestion(form: MFForm, rules: BusinessRules, lastQuestion: Int, direction: Int) -> DisplayQuestions {
        let count = form.questions.count
        var found = false
        var current = lastQuestion + direction
        var questions: [MFQuestion] = []
        
        while !found && ((direction > 0 && current < count) || (direction < 0 && current > -1)) {
            let q = form.questions[current]
            if isQuestionValidForDisplay(form: form, question: q, rules: rules) {
                questions.append(q)
                found = true
            } else {
                current += direction
            }
        }
        
        let atStart = findQuestionBoundary(form: form, rules: rules, start: current, direction: -1) < 0
        let atEnd = findQuestionBoundary(form: form, rules: rules, start: current, direction: +1) >= count
        
        return DisplayQuestions(questions: questions, atEnd: atEnd, atStart: atStart, numberOfControls: questions.count, lastItem: current)
    }
    
    private func getQuestionsInSection(form: MFForm, rules: BusinessRules, lastSection: Int, direction: Int) -> DisplayQuestions {
        let count = form.sections.count
        var found = false
        var current = lastSection + direction
        var activeSection: MFSection?
        
        while !found && ((direction > 0 && current < count) || (direction < 0 && current > -1)) {
            let s = form.sections[current]
            if isSectionValidForDisplay(form: form, section: s, rules: rules) {
                activeSection = s
                found = true
            } else {
                current += direction
            }
        }
        
        let atStart = findSectionBoundary(form: form, rules: rules, start: current, direction: -1) < 0
        let atEnd = findSectionBoundary(form: form, rules: rules, start: current, direction: +1) >= count
        
        return getQuestionsForSection(form: form, section: activeSection!, atStart: atStart, atEnd: atEnd, lastItem: current)
    }
    
    private func getQuestionsInForm(_ form: MFForm) -> DisplayQuestions {
        var controlCount = 0
        let questions: [MFQuestion] = form.questions
        
        for q in form.questions {
            controlCount += q.controls.count
        }
        
        return DisplayQuestions(questions: questions, atEnd: true, atStart: true, numberOfControls: controlCount, lastItem: 1)
    }
    
    private func findQuestionBoundary(form: MFForm, rules: BusinessRules, start: Int, direction: Int) -> Int {
        let questionCount = form.questions.count
        var boundary = direction < 0 ? -1 : questionCount
        var found = false
        var outOfBounds = false
        var current = start + direction
        
        if current < 0 || current > questionCount {
            return boundary
        }
        
        repeat {
            let q = form.questions[current]
            if self.isQuestionValidForDisplay(form: form, question: q, rules: rules) {
                found = true
                break
            } else {
                current += direction
                outOfBounds = current < 0 || current > questionCount
            }
        } while !found && !outOfBounds
        
        boundary = current
        return boundary
    }
    
    private func findSectionBoundary(form: MFForm, rules: BusinessRules, start: Int, direction: Int) -> Int {
        let sectionCount = form.sections.count
        var boundary = direction < 0 ? -1 : sectionCount
        var found = false
        var outOfBounds = false
        var current = start + direction
        
        if current < 0 || current > sectionCount {
            return boundary
        }
        
        repeat {
            let s = form.sections[current]
            if self.isSectionValidForDisplay(form: form, section: s, rules: rules) {
                found = true
                break
            } else {
                current += direction
                outOfBounds = current < 0 || current > sectionCount
            }
        } while !found && !outOfBounds
        
        boundary = current
        return boundary
    }
    
    private func isQuestionValidForDisplay(form: MFForm, question: MFQuestion, rules: BusinessRules) -> Bool {
        guard let ruleName = question.ruleToMatch else {
            return true
        }
        return rules.evaluateRule(ruleName, data: form.data)
    }
    
    private func isSectionValidForDisplay(form: MFForm, section: MFSection, rules: BusinessRules) -> Bool {
        guard let ruleName = section.ruleToMatch else {
            return true
        }
        return rules.evaluateRule(ruleName, data: form.data)
    }
    
    private func getQuestionsForSection(form: MFForm, section: MFSection, atStart: Bool, atEnd: Bool, lastItem: Int) -> DisplayQuestions {
        
        let questionsInSection = form.questions.filter( {$0.sectionId == section.id })
        let controlCount = questionsInSection.count
        
        return DisplayQuestions(
            questions: questionsInSection,
            atEnd: atEnd,
            atStart: atStart,
            numberOfControls: controlCount,
            lastItem: lastItem)
    }
}

public struct DisplayQuestions {
    let questions: [MFQuestion]
    let atEnd: Bool
    let atStart: Bool
    let numberOfControls: Int
    let lastItem: Int
}
