//
//  Appliable.swift
//  ColorPixel
//
//  Created by Vladislav Glumov on 26.12.23.
//

import Foundation

protocol Appliable { }

extension Appliable {

    @discardableResult
    func apply(_ handler: (Self) -> Void) -> Self {
        handler(self)
        return self
    }
}

extension NSObject: Appliable {
}
