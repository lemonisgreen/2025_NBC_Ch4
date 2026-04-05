//
//  WeatherSession.swift
//  SherlDog
//
//  Created by 최규현 on 4/5/26.
//

import RxSwift
import WeatherKit
import CoreLocation

struct WeatherState {
    let temperature: Double
    let currentWeather: WeatherCondition
    let hourlyWeather: [HourWeather]
}

final class WeatherSession {
    
    static let shared = WeatherSession()
    
    private init() { }
    
    func fetchWeather(for location: CLLocation) -> Single<WeatherState?> {
        return Single.create { single in
            Task {
                do {
                    let weather = try await WeatherService.shared.weather(for: location)
                    
                    single(.success(WeatherState(
                        temperature: weather.currentWeather.temperature.value,
                        currentWeather: weather.currentWeather.condition,
                        hourlyWeather: Array(weather.hourlyForecast.prefix(2))
                    )))
                } catch {
                    single(.failure(error))
                }
            }
            
            return Disposables.create()
        }
    }
}
