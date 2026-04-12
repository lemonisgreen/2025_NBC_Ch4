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
    
    private let locationManager: CLLocationManager
    
    private let disposeBag = DisposeBag()
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    func makeWeatherState() -> Observable<WeatherState> {
        return self.locationManager.rx.didUpdateLocations
            .throttle(.seconds(2), latest: true, scheduler: MainScheduler())
            .compactMap { $0.locations.last }
            .flatMapLatest { [weak self] location -> Observable<WeatherState> in
                guard let self else { return .empty() }
                
                return self.fetchWeather(for: location)
            }
    }
    
    private func fetchWeather(for location: CLLocation) -> Observable<WeatherState> {
        return Observable.create { observer in
            let task = Task {
                do {
                    let weather = try await WeatherService.shared.weather(for: location)
                    
                    observer.onNext(WeatherState(
                        temperature: weather.currentWeather.temperature.value,
                        currentWeather: weather.currentWeather.condition,
                        hourlyWeather: Array(weather.hourlyForecast.prefix(2))
                    ))
                } catch {
                    observer.onError(error)
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}


extension WeatherState {
    static let initial = WeatherState(
        temperature: 0,
        currentWeather: .clear,
        hourlyWeather: []
    )
}
