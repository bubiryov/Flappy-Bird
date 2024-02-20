//
//  ObjectBitMask.swift
//  Flappy Bird
//
//  Created by Egor Bubiryov on 19.02.2024.
//

import Foundation

struct ObjectBitMask {
    static let bird: UInt32 = 0b0001
    static let obstacle: UInt32 = 0b0010
    static let scoreLine: UInt32 = 0b0100
}
