//
//  XMLNodeGeneric.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/24/17.
//

import Foundation

public class XMLNodeGeneric {
    let owner: XMLNodeGeneric?

    init(withOwner owner: XMLNodeGeneric?) {
        self.owner = owner
    }
}
