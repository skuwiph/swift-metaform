//
//  File.swift
//  
//
//  Created by Ian Seckington on 13/03/2020.
//

import XCTest
@testable import MetaForm

final class BusinessRuleTests: XCTestCase {
    
    func testRuleEqualityString() {
        let r = BusinessRules()
        let f = MetaFormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .Equals, value: "A")
        
        f.setValue("test", value: "A")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
     
    static var allTests = [
        ("testRuleEqualityString", testRuleEqualityString)
    ]
}
