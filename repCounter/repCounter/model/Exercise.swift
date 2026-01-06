//
//  Item.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 06.01.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
