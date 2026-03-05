//
//  StreakService.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation

struct StreakService {

    /// Returns the updated streak count.
    /// - already logged today  → same streak (no change)
    /// - last log was yesterday → streak + 1
    /// - anything else          → reset to 1 (new streak starts today)
    static func updatedStreak(lastLoggedDate: Date?, currentStreak: Int, today: Date = .now) -> Int {
        let calendar = Calendar.current

        guard let last = lastLoggedDate else {
            return 1  // first ever log
        }

        if calendar.isDate(last, inSameDayAs: today) {
            return currentStreak  // already logged today
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(last, inSameDayAs: yesterday) {
            return currentStreak + 1  // consecutive day
        }

        return 1  // streak broken, start fresh
    }
}
