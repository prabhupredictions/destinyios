//
//  Item.swift
//  ios_app
//
//  Created by I074917 on 17/12/25.
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
