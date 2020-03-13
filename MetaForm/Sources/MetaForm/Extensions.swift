//
//  File.swift
//  
//
//  Created by Ian Seckington on 10/03/2020.
//

import Foundation

extension String {
    var numberOfWords: Int {
        var count = 0
        let range = self.startIndex..<self.endIndex
        enumerateSubstrings(in: range, options: [.byWords, .substringNotRequired, .localized], { _, _, _, _ -> () in
            count += 1
        })
        return count
    }
    
    func split(with: Character, andTakePart: Int) -> String {
        if !self.isEmpty {
            let split = self.split(separator: with)
            if split.count >= andTakePart {
                return String(split[andTakePart])
            }
        }
        return ""
    }
}
