//
//  File.swift
//  
//
//  Created by Ian Seckington on 09/03/2020.
//

import Foundation


enum MetaFormDrawType {
    case SingleQuestion
    case EntireSection
    case EntireForm
}

enum ControlLayoutStyle {
    case Vertical
    case Horizontal
}

enum MetaFormControlType {
    case Label
    case Html
    case Text
    case Option
    case OptionMulti
    case Date
    case Time
    case DateTime
    case TelephoneAndIddCode
    case Toggle
    case Slider
}

enum MetaFormTextType {
    case SingleLine
    case MultiLine
    case Password
    case Email
    case URL
    case TelephoneNumber
    case PostalCode
    case Numeric
}

enum MetaFormDateType {
    case Full
    case MonthYear
}
