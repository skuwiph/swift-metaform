//
//  FormData.swift
//  
//
//  Created by Ian Seckington on 10/03/2020.
//

import Foundation

class MetaFormData {
    private var data = [String: String]()
    private var forceLowerCase = false
    
    func getValue(name: String) -> String {
        let fieldName = self.correctFieldName(name: name)
        return self.data[fieldName] ?? ""
    }
    
    func setValue(name: String, value: String) {
        let fieldName = self.correctFieldName(name: name)
        self.data[fieldName] = value
    }
    
    private func correctFieldName(name: String) -> String {
        return self.forceLowerCase ? name.lowercased() : name
    }
}
