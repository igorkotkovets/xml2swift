//
//  NSObject+Extensions.swift
//  XML2Swift
//
//  Created by igork on 9/9/19.
//

import Foundation

extension NSObject {
    func withUnretainedReference<T, R>(_ work: (UnsafePointer<T>) -> R) -> R {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque().assumingMemoryBound(to: T.self)
        return work(selfPtr)
    }

    func withOpaqueUnretainedReference<R>(_ work: (UnsafeMutableRawPointer) -> R) -> R {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        return work(selfPtr)
    }
}
