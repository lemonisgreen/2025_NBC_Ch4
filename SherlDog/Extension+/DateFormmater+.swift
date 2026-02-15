//
//  DateFormmater+.swift
//  SherlDog
//
//  Created by JIN LEE on 7/18/25.
//

import UIKit

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let yyyyMMddSlash: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy / MM / dd"
        return formatter
    }()
    
    static let yyyyMMddDot: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
    
    static let yyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return formatter
    }()
    
    static func todayStyle(_ date: Date) -> DateFormatter {
        let formatter = self.checkToday(date)
        ? self.setTodayStyle(date)
        : self.yyyyMMddDot
        
        return formatter
    }
    
    private static func setTodayStyle(_ date: Date) -> DateFormatter {
        let formatter = DateFormatter()
        
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        var format: String
        
        if diff < 60 {
            format = "방금 전"
        } else if diff < 3600 {
            format = "\(Int(diff / 60))분 전"
        } else {
            format = "\(Int(diff / 3600))시간 전"
        }
        
        formatter.dateFormat = format
        return formatter
    }
    
    private static func checkToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let otherDay = calendar.startOfDay(for: date)
        return today == otherDay
    }
}
