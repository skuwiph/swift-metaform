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
    
    func testEmail() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.Email)
            .addValidator(MFValidator.Email(message: "Answer must be an email address"))
        
        // Empty should be permitted (the required validator must be added if empty is incorrect)
        XCTAssertTrue(form.isValid(false))
        
        // Valid emails
        let valids = ["frank@example.com", "frank.smith@ex.co", "_frank@a.co.nz", "jack@email.example.com", "first-last@test.com", "1234@ucl.ac.uk", "first+last@example.com", "email@exa-one.com", "______@example.com"]
        
        for v in valids {
            form.setValue("t1", value: v)
            XCTAssertTrue(form.isValid(false), "Value \(v) should be a valid email")
        }
        
        // Invalid emails
        let invalids = ["frank.example.com", "plainaddress"]
        for v in invalids {
            form.setValue("t1", value: v)
            XCTAssertFalse(form.isValid(false), "Value \(v) should be an invalid email")
        }
    }
    
    func testDate() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.Date(message: "Answer must be date if present"))
        
        // Empty should be valid (no required)
        XCTAssertTrue(form.isValid(false))
        
        let invalids = ["A", "1990-2-31", "2010-17-1", "2009-10-44"]
        for v in invalids {
            form.setValue("t1", value: v)
            XCTAssertFalse(form.isValid(false), "\(v) is invalid")
        }

        let valids = ["2020-04-10", "1999-3-10", "2004-10-1", "2000-2-29"]
        for v in valids {
            form.setValue("t1", value: v)
            XCTAssertTrue(form.isValid(false), "\(v) is valid")
        }
    }
    
    func testDateTimes() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.DateTime(message: "Answer must be date if present"))
        
        // Empty should be valid (no required)
        XCTAssertTrue(form.isValid(false))
        
        let invalids = ["A", "1990-2-31 11:30", "2010-17-1 99:01", "2009-10-1 25:30"]
        for v in invalids {
            form.setValue("t1", value: v)
            XCTAssertFalse(form.isValid(false), "\(v) is invalid")
        }
        
        let valids = ["2020-04-10 9:30", "1999-3-10 14:50", "2004-10-1 06:45", "2000-2-29 18:59"]
        for v in valids {
            form.setValue("t1", value: v)
            XCTAssertTrue(form.isValid(false), "\(v) is valid")
        }
    }
    
    func testDateAfter() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.DateMustBeAfter("2010-10-30", message: "Answer must be after 30/10/2010 date if present"))
        
        // Empty should be valid (no required)
        XCTAssertTrue(form.isValid(false))
        
        let invalids = ["2010-10-29", "1990-2-01", "2010-10-29 20:30", "2009-10-1 12:30"]
        for v in invalids {
            form.setValue("t1", value: v)
            XCTAssertFalse(form.isValid(false), "\(v) is invalid")
        }
        
        let valids = ["2020-04-10 9:30", "2011-3-10 14:50", "2010-10-31", "2010-11-1 18:59"]
        for v in valids {
            form.setValue("t1", value: v)
            XCTAssertTrue(form.isValid(false), "\(v) is valid")
        }
    }
    
    func testDateBefore() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.DateMustBeBefore("2010-10-30", message: "Answer must be before 30/10/2010 date if present"))
        
        // Empty should be valid (no required)
        XCTAssertTrue(form.isValid(false))
        
        let valids = ["2010-10-29", "1990-2-01", "2010-10-29 20:30", "2009-10-1 12:30"]
        for v in valids {
            form.setValue("t1", value: v)
            XCTAssertTrue(form.isValid(false), "\(v) is valid")
        }
        
        let invalids = ["2020-04-10 9:30", "2011-3-10 14:50", "2010-10-31", "2010-11-1 18:59"]
        for v in invalids {
            form.setValue("t1", value: v)
            XCTAssertFalse(form.isValid(false), "\(v) is invalid")
        }
    }
    
    func testWordCount() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTextControl(name: "t1", textType: MetaFormTextType.SingleLine)
            .addValidator(MFValidator.MinimumWordCount(10, message: "Answer must have >10 words"))
        
        XCTAssertFalse(form.isValid(false))
        
        form.setValue("t1", value: "A B C D E F G H I J")
        
        XCTAssertTrue(form.isValid(false))
    }
    
    static var allTests = [
        ("testRequired", testRequired),
        ("testAnswerMustMatchSimple", testAnswerMustMatchSimple),
        ("testAnswerMustMatchField", testAnswerMustMatchField),
        ("testEmail", testEmail),
        ("testDate", testDate),
        ("testDateTimes", testDateTimes),
        ("testDateAfter", testDateAfter),
        ("testDateBefore", testDateBefore),
        ("testWordCount", testWordCount)
    ]
}
