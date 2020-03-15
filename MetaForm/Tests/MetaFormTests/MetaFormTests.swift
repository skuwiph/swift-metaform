import XCTest
@testable import MetaForm

final class MetaFormTests: XCTestCase {
    
    func testDateExtraction() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addDateControl(name: "d1", dateType: MetaFormDateType.Full)
        
        XCTAssert(form.questions.count == 1)
        
        form.setValue("d1", value: "2019-10-11")
        
        // Get date control out
        if let c = form.getQuestion(name: "q1")?.controls[0] as! MFDateControl? {
            XCTAssert(c.getDay(form: form) == "11")
            XCTAssert(c.getMonth(form: form) == "10")
            XCTAssert(c.getYear(form: form) == "2019")
        
            form.setValue("d1", value: "2021-1-3")
            XCTAssert(c.getDay(form: form) == "3")
            XCTAssert(c.getMonth(form: form) == "1")
            XCTAssert(c.getYear(form: form) == "2021")
            
        }
        
    }
    
    func testTimeExtraction() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTimeControl(name: "t1", minuteStep: 15, hourStart: 8, hourEnd: 20)
        
        XCTAssert(form.questions.count == 1)
        
        form.setValue("t1", value: "10:45")
        
        let t1 = MFTimeControl.getHourPart("10:45")
        let t2 = MFTimeControl.getHourPart("9:45")
        let t3 = MFTimeControl.getHourPart("2020-1-3 14:45")
        XCTAssertTrue(t1 == "10", "Couldn't extract time from string \(t1)")
        XCTAssertTrue(t2 == "09", "Couldn't extract time from string \(t2)")
        XCTAssertTrue(t3 == "14", "Couldn't extract time from string \(t3)")

        let t4 = MFTimeControl.getMinutePart("10:45")
        let t5 = MFTimeControl.getMinutePart("9:07")
        let t6 = MFTimeControl.getMinutePart("2020-12-03 14:35")
        XCTAssertTrue(t4 == "45", "Couldn't extract time from string \(t4)")
        XCTAssertTrue(t5 == "07", "Couldn't extract time from string \(t5)")
        XCTAssertTrue(t6 == "35", "Couldn't extract time from string \(t6)")

    }
    
    func testTimeLists() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTimeControl(name: "t1", minuteStep: 15, hourStart: 8, hourEnd: 20)
        
        XCTAssert(form.questions.count == 1)
        if let c = form.getQuestion(name: "t1")?.controls[0] as! MFTimeControl? {
            let ml = c.getHourList()
            XCTAssertTrue(ml[0] == "08", "First item should be 08, not \(ml[0])")
            XCTAssertTrue(ml.last == "20", "Last item should be 20, not \(String(describing: ml.last))")

            let mins = c.getHourList()
            XCTAssertTrue(mins[0] == "00", "First item should be 00, not \(mins[0])")
            XCTAssertTrue(mins.last == "45", "Last item should be 45, not \(String(describing: mins.last))")
        }
    }
    
    func testFieldReplacement() {
        let test = MetaForm.getFieldName(from: "[field]")
        XCTAssertTrue(test == "field", "Expected 'field' not \(test)")
        
        let check = MetaForm.isFieldReference(value: "[myField]")
        XCTAssertTrue(check.isField, "Should be a field reference")
        XCTAssertTrue(check.fieldName == "myField", "Should have extracted the correct field")

        let check2 = MetaForm.isFieldReference(value: "value")
        XCTAssertFalse(check2.isField, "Should not be a field reference")
    }

    func testVariableReplacement() {
        let test = MetaForm.getVariable(from: "%TODAY")
        XCTAssertTrue(test == "TODAY", "Expected 'TODAY' not \(test)")
        
        let check = MetaForm.isVariableReference(value: "%TODAY")
        XCTAssertTrue(check.isVariable, "Should be a variable reference")
        XCTAssertTrue(check.variableName == "TODAY", "Should have extracted the correct variable")
        
        let check2 = MetaForm.isVariableReference(value: "value")
        XCTAssertFalse(check2.isVariable, "Should not be a variable reference")
    }
    
    func testDisplayRuleFalsePassesValidation() {
        let rules = BusinessRules()
        
        _ = rules
            .addRule(name: "YesNoIsYes", matchType: .MatchAny)
            .addPart(field: "yesOrNo", comparison: .Equals, value: "Y")
        
        var yn = [MFOptionValue]()
        yn.append( MFOptionValue(code: "Y", description: "Yes"))
        yn.append( MFOptionValue(code: "N", description: "No"))

        let form = MetaForm(name: "test", title: "Test Form", drawType: .EntireForm)
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addOptionControl(name: "yesOrNo", options: MFOptions.OptionFromList(options: yn, emptyItem: nil, expandOptions: true))
        
        _ = form
            .addQuestion(name: "q2", caption: "Question to be displayed if previous is Y")
            .setDisplayRule("YesNoIsYes")
            .addDateControl(name: "dateInFuture", dateType: .Full)
            .addLabel("Future date")
            .addValidator(MFValidator.Required(message: "Please answer"))
            .addValidator(MFValidator.Date(message: "Answer must be a valid date"))
            .addValidator(MFValidator.DateMustBeAfter("%TODAY", message: "Must be after today"))
        
        form.setValue("yesOrNo", value: "N")
        form.rules = rules
        
        XCTAssertTrue(form.isValid(), "Expected form to be valid")
    }
    
    func testDisplayRuleTrueFailsValidation() {
        let rules = BusinessRules()
        
        _ = rules
            .addRule(name: "YesNoIsYes", matchType: .MatchAny)
            .addPart(field: "yesOrNo", comparison: .Equals, value: "Y")
        
        var yn = [MFOptionValue]()
        yn.append( MFOptionValue(code: "Y", description: "Yes"))
        yn.append( MFOptionValue(code: "N", description: "No"))
        
        let form = MetaForm(name: "test", title: "Test Form", drawType: .EntireForm)
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addOptionControl(name: "yesOrNo", options: MFOptions.OptionFromList(options: yn, emptyItem: nil, expandOptions: true))
        
        _ = form
            .addQuestion(name: "q2", caption: "Question to be displayed if previous is Y")
            .setDisplayRule("YesNoIsYes")
            .addDateControl(name: "dateInFuture", dateType: .Full)
            .addLabel("Future date")
            .addValidator(MFValidator.Required(message: "Please answer"))
            .addValidator(MFValidator.Date(message: "Answer must be a valid date"))
            .addValidator(MFValidator.DateMustBeAfter("%TODAY", message: "Must be after today"))
        
        form.setValue("yesOrNo", value: "Y")
        form.rules = rules
        
        XCTAssertFalse(form.isValid(), "Expected form to be invalid")
    }
    
    static var allTests = [
        ("testDataExtraction", testDateExtraction),
        ("testTimeExtraction", testTimeExtraction),
        ("testTimeLists", testTimeLists),
        ("testFieldReplacement", testFieldReplacement),
        ("testVariableReplacement", testVariableReplacement),
        ("testDisplayRuleFalsePassesValidation", testDisplayRuleFalsePassesValidation),
        ("testDisplayRuleTrueFailsValidation", testDisplayRuleTrueFailsValidation)
    ]
}
