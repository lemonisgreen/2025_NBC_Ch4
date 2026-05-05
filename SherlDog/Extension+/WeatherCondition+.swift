//
//  WeatherCondition+.swift
//  SherlDog
//
//  Created by 최규현 on 5/3/26.
//

import WeatherKit

extension WeatherCondition {
    var isRainRelated: Bool {
        switch self {
        case .drizzle,
             .rain,
             .heavyRain,
             .freezingRain,
             .freezingDrizzle,
             .sunShowers,
             .thunderstorms,
             .isolatedThunderstorms,
             .scatteredThunderstorms,
             .strongStorms:
            return true

        default:
            return false
        }
    }
}
