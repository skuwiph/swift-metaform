//
//  Delegates.swift
//  
//
//  Created by Ian Seckington on 16/03/2020.
//

import Foundation

public struct FormDataChanged {
    var fieldName: String
    var oldValue: String?
    var newValue: String?
}

public struct ControlValidityChanged {
    var controlName: String
    var validator: String
    var isValid: Bool
}

public extension Notification.Name {
    static let dataWasChanged = Notification.Name("mfDataChanged")
    static let controlValidityDidChange = Notification.Name("mfcontrolValidityDidChange")
}
