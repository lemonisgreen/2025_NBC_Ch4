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
    
    static let yyMMdd: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyMMdd"
            return formatter
        }()
}
