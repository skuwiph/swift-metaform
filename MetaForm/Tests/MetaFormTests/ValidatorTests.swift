//
//  ValidatorTests.swift
//  
//
//  Created by Ian Seckington on 12/03/2020.
//

import Foundation
import XCTest
@testable import MetaForm

final class ValidatorTests: XCTestCase {
    
    func testRequired() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.Required(message: "Answer is required"))
        
        XCTAssertFalse(form.isValid(false))
        
        form.setValue("t1", value: "A")
        
        XCTAssertTrue(form.isValid(false))
    }
    
    func testAnswerMustMatchSimple() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.AnswerMustMatch("Y", message: "Answer must be Y"))
        
        XCTAssertFalse(form.isValid(false))
        
        form.setValue("t1", value: "Y")
        
        XCTAssertTrue(form.isValid(false))
    }

    func testAnswerMustMatchField() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.AnswerMustMatch("[checkField]", message: "Answer must be the same as checkField"))

        form.setValue("checkField", value: "Montaigne")

        // Empty check
        XCTAssertFalse(form.isValid(false))
        
        // Erroneous check
        form.setValue("t1", value: "Descartes")
        
        XCTAssertFalse(form.isValid(false))
        
        // Correct
        form.setValue("t1", value: "Montaigne")
        
        XCTAssertTrue(form.isValid(false))
    }
    
    static var allTests = [
        ("testRequired", testRequired),
        ("testAnswerMustMatchSimple", testAnswerMustMatchSimple),
        ("testAnswerMustMatchField", testAnswerMustMatchField)
    ]
}
