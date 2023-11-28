//
//  Sequence+Helpers.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 4/5/23.
//

import Foundation

internal extension Sequence where Element: Hashable {
    
    var unique: [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
