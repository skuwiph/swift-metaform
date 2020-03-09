import Foundation

struct MetaForm {
    var name: String
    var title: String
    var version: UInt8
    var dateModified = Date()
    var dataSource: String?
    var drawType: MetaFormDrawType
    var allowSaves: Bool = false
    var sections: [MFSection] = []
    var questions: [MFQuestion] = []
    
}

struct MFSection {
    var id: UInt8
    var title: String
    var ruleToMatch: String?
}

struct MFQuestion {
    var sectionId: UInt8
    var name: String
    var caption: String?
    var captionFootnote: String?
    var ruleToMatch: String?
    var controlLayout: ControlLayoutStyle = ControlLayoutStyle.Vertical
    var controls: [MFControl] = []
    var readonly = false
    var available = true
}

struct MFAnimation {
    var event: String
    var name: String
}

