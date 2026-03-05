//
//  LiftEntry.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

@Model
final class LiftEntry {
    var id: UUID
    var date: Date
    var liftType: String
    var weight: Double
    var reps: Int
    var e1RM: Double

    init(date: Date = .now, liftType: String, weight: Double, reps: Int) {
        self.id = UUID()
        self.date = date
        self.liftType = liftType
        self.weight = weight
        self.reps = reps
        self.e1RM = weight * (1.0 + Double(reps) / 30.0)
    }
}
