import XCTest
@testable import MetaForm

final class MetaFormTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(MetaForm().name, "Hello, World!")
    }
    
    func testDateExtraction() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addDateControl(name: "d1", dateType: MetaFormDateType.Full)
        
        XCTAssert(form.questions.count == 1)
        
        form.setValue(name: "d1", value: "2019-10-11")
        
        // Get date control out
        if let c = form.getQuestion(name: "q1")?.controls[0] as! MFDateControl? {
            XCTAssert(c.getDay(form: form) == "11")
            XCTAssert(c.getMonth(form: form) == "10")
            XCTAssert(c.getYear(form: form) == "2019")
        }
        
    }
    
    func testTimeExtraction() {
        let form = MetaForm(name: "test", title: "Test Form")
        _ = form
            .addQuestion(name: "q1", caption: "Test Question")
            .addTimeControl(name: "t1", minuteStep: 15, hourStart: 8, hourEnd: 20)
        
        XCTAssert(form.questions.count == 1)
        
        form.setValue(name: "t1", value: "10:45")
        
        let t1 = MFTimeControl.getHourPart(value: "10:45")
        let t2 = MFTimeControl.getHourPart(value: "9:45")
        let t3 = MFTimeControl.getHourPart(value: "2020-1-3 14:45")
        XCTAssertTrue(t1 == "10", "Couldn't extract time from string \(t1)")
        XCTAssertTrue(t2 == "09", "Couldn't extract time from string \(t2)")
        XCTAssertTrue(t3 == "14", "Couldn't extract time from string \(t3)")
    }

    static var allTests = [
        ("testExample", testExample),
        ("testDataExtraction", testDateExtraction),
        ("testTimeExtraction", testTimeExtraction)
    ]
}
