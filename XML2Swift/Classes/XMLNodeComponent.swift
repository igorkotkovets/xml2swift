//
//  XMLNodeGeneric.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/24/17.
//

import Foundation

public protocol XMLNodeComponent {
    var name: String? { get }
    var childCount: UInt { get }
    func child(at index: UInt) -> XMLNode?
}
