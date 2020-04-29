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
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .Equals, value: "A")
        
        f.setValue("test", value: "A")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleEqualityNumber() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .Equals, value: "123", evaluationType: .Numeric)
        
        f.setValue("test", value: "123")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleEqualityDate() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .Equals, value: "2020-05-01", evaluationType: .DateTime)
        
        f.setValue("test", value: "2020-5-1")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleEqualityBool() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .Equals, value: "Y", evaluationType: .Bool)
        
        f.setValue("test", value: "Y")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleInequalityString() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .NotEquals, value: "A")
        
        f.setValue("test", value: "B")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
     
    func testRuleInequalityNumber() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .NotEquals, value: "123", evaluationType: .Numeric)
        
        f.setValue("test", value: "1234")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleInequalityDate() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .NotEquals, value: "2020-05-01", evaluationType: .DateTime)
        
        f.setValue("test", value: "2020-5-16")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    func testRuleInequalityBool() {
        let r = BusinessRules()
        let f = FormData()
        
        _ = r
            .addRule(name: "r1", matchType: .MatchAny)
            .addPart(field: "test", comparison: .NotEquals, value: "Y", evaluationType: .Bool)
        
        f.setValue("test", value: "false")
        
        XCTAssertTrue(r.evaluateRule("r1", data: f), "Rule should evaluate true")
    }
    
    static var allTests = [
        ("testRuleEqualityString", testRuleEqualityString),
        ("testRuleEqualityNumeric", testRuleEqualityNumber),
        ("testRuleEqualityDate", testRuleEqualityDate),
        ("testRuleEqualityBool", testRuleEqualityBool),
        ("testRuleInequalityString", testRuleInequalityString),
        ("testRuleInequalityNumeric", testRuleInequalityNumber),
        ("testRuleInequalityDate", testRuleInequalityDate),
        ("testRuleInequalityBool", testRuleInequalityBool)
    ]
}
