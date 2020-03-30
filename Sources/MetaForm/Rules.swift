//
//  Rules.swift
//
//  Created by Ian Seckington on 13/03/2020.
//

import Foundation

public class BusinessRules {
    var rules: [String: BusinessRule] = [:]
    
    init() {
        self.rules = [:]
    }
    
    public func addRule(name: String, matchType: RuleMatchType) -> BusinessRule {
        if self.rules.index(forKey: name) != nil {
            // This rule has already been added
            // TODO(Ian): throw an exception. Although
            // I hate exceptions
            debugPrint("Rule \(name) has already been added")
        }
        let r = BusinessRule(name: name, matchType: matchType)
        self.rules[r.name] = r
        return r;
    }
    
    public func evaluateRule(_ name: String, data: MetaFormData) -> Bool {
        if let r = self.rules[name] {
            debugPrint("Evaluating rule: \(name)")
            return r.evaluate(data: data)
        }
        
        debugPrint("\(name) was not found!")
        return false
    }
}

public class BusinessRule {
    var name: String
    var matchType: RuleMatchType
    var parts: [RulePart]
    
    init(name: String, matchType: RuleMatchType) {
        self.name = name
        self.matchType = matchType
        self.parts = []
    }
    
    public func addPart(field: String, comparison: RuleComparison, value: String, evaluationType: ForceEvaluationType? = nil) -> BusinessRule {
        let p = RulePart(fieldName: field, comparison: comparison, value: value, evaluationType: evaluationType)
        self.parts.append(p)
        return self
    }
    
    public func addRangePart(field: String, min: String, max: String, evaluationType: ForceEvaluationType? = nil) -> BusinessRule {
        let p = RulePart(fieldName: field, comparison: .Between, min: min, max: max, evaluationType: evaluationType)
        self.parts.append(p)
        return self
    }
    
    public func evaluate(data: MetaFormData) -> Bool {
        var success = false
        
        for p in self.parts {
            success = p.evaluate(data: data)
            
            if success && self.matchType == .MatchAny {
                return true
            }
            
            if !success && self.matchType == .MatchAll {
                return false
            }
        }
        
        return success
    }

}

public protocol BRPRulePart {
    func evaluate(data: MetaFormData) -> Bool
}

public struct RulePart: BRPRulePart {
    var fieldName: String
    var comparison: RuleComparison
    var forceEvaluationAsType: ForceEvaluationType = .Default
    var value: String? = nil
    
    var min: String? = nil
    var max: String? = nil
    
    init(fieldName: String, comparison: RuleComparison, value: String? = nil, min: String? = nil, max: String? = nil, evaluationType: ForceEvaluationType? = nil) {
        self.fieldName = fieldName
        self.comparison = comparison
        self.value = value
        self.min = min
        self.max = max
        self.forceEvaluationAsType = evaluationType ?? .Default
    }
    
    public func evaluate(data: MetaFormData) -> Bool {
        var success = false
        
        // Get the value to compare against
        let comparedValue = data.getValue(self.fieldName)
        
        debugPrint("evaluating \(comparedValue) against \(String(describing: self.value))")
        
        switch self.comparison {
        case .Equals:
            success = self.evaluateAsTrue(comparedValue, data: data)
        case .NotEquals:
            success = !self.evaluateAsTrue(comparedValue, data: data)
        case .GreaterThan:
            success = self.evaluateGreaterThan(comparedValue, data: data)
        case .LessThan:
            success = self.evaluateLessThan(comparedValue, data: data)
        case .Contains:
            success = self.evaluateContains(comparedValue, data: data)
        case .Between:
            success = self.evaluateBetweenThan(comparedValue, data: data)
        }
        
        return success
    }
    
    private func evaluateAsTrue(_ comparedValue: String, data: MetaFormData) -> Bool {
        switch self.forceEvaluationAsType {
        case .Default:
            return comparedValue.elementsEqual(self.value!)
        case .Bool:
            let nv = self.convertValueToBool(comparedValue)
            let sv = self.convertValueToBool(self.value!)
            return nv == sv
        case .Numeric:
            guard let nv = Int(comparedValue), let sv = Int(self.value!) else {
                return false
            }
            return nv == sv
        case .DateTime:
            guard let nv = data.getAsDateTime(comparedValue),
                let sv = data.getAsDateTime(self.value!) else {
                    return false
                }
                return nv == sv
        }
    }
    
    private func evaluateGreaterThan(_ comparedValue: String, data: MetaFormData) -> Bool {
        if self.forceEvaluationAsType == .DateTime {
            guard let nv = data.getAsDateTime(comparedValue),
                let sv = data.getAsDateTime(self.value!) else {
                    return false
            }
            return nv > sv
        } else if self.forceEvaluationAsType == .Numeric {
            guard let nv = Int(comparedValue), let sv = Int(self.value!) else {
                return false
            }
            return nv > sv
        }
        
        return false
    }
    
    private func evaluateLessThan(_ comparedValue: String, data: MetaFormData) -> Bool {
        if self.forceEvaluationAsType == .DateTime {
            guard let nv = data.getAsDateTime(comparedValue),
                let sv = data.getAsDateTime(self.value!) else {
                    return false
            }
            return nv < sv
        } else if self.forceEvaluationAsType == .Numeric {
            guard let nv = Int(comparedValue), let sv = Int(self.value!) else {
                return false
            }
            return nv < sv
        }
        
        return false
    }
    
    private func evaluateContains(_ comparedValue: String, data: MetaFormData) -> Bool {
        if comparedValue.contains(",") {
            let splits = comparedValue.split(separator: ",")
            for s in splits {
                if String(s) == self.value {
                    return true
                }
            }
            return false
        } else {
            return comparedValue == self.value
        }
    }
    
    private func evaluateBetweenThan(_ comparedValue: String, data: MetaFormData) -> Bool {
        if self.forceEvaluationAsType == .DateTime {
            guard let nv = data.getAsDateTime(comparedValue),
                let min = data.getAsDateTime(self.min!),
                let max = data.getAsDateTime(self.max!) else {
                    return false
            }
            return nv > min && nv < max
        } else if self.forceEvaluationAsType == .Numeric {
            guard let nv = Int(comparedValue),
                let min = Int(self.min!),
                let max = Int(self.max!) else {
                return false
            }
            return nv > min && nv < max
        }
        
        return false
    }
    
    private func convertValueToBool(_ value: String) -> Bool {
        if value.uppercased() == "Y" || value.uppercased() == "TRUE" || value == "1" {
            return true
        }
        return false
    }
}

public enum RuleMatchType {
    case MatchAll
    case MatchAny
}

public enum RuleComparison: Int {
    case Equals = 1
    case NotEquals
    case LessThan
    case GreaterThan
    case Contains
    case Between
}

public enum ForceEvaluationType {
    case Default
    case Bool
    case DateTime
    case Numeric
}
