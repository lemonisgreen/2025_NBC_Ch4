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
    let temperature: Int
    let currentWeather: WeatherCondition
    let hourlyWeather: [HourWeather]
}

final class WeatherSession {
    
    struct Config {
        let refreshInterval: Int = (60 * 5) // 5분
        let refreshDistance: Double = 500 // 500미터
    }
    
    private let config = Config()
    private let locationManager: CLLocationManager
    private var lastWeatherLocation: CLLocation?
    private var shouldFetchWeather = true
    
    private let disposeBag = DisposeBag()
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    func makeWeatherState() -> Observable<WeatherState> {
        return self.locationManager.rx.didUpdateLocations
            .throttle(.seconds(self.config.refreshInterval), latest: true, scheduler: MainScheduler())
            .compactMap { $0.locations.last }
            .filter { [weak self] location in
                guard let self,
                        self.shouldFetchWeather else { return false }
                guard let lastLocation = self.lastWeatherLocation else {
                    self.lastWeatherLocation = location
                    return true
                }
                
                let distance = location.distance(from: lastLocation)
                
                guard distance >= self.config.refreshDistance else { return false }
                
                self.lastWeatherLocation = location
                return true
                
            }
            .flatMapLatest { [weak self] location -> Observable<WeatherState> in
                guard let self else { return .empty() }
                
                return self.fetchWeather(for: location)
            }
    }
    
    func pauseWeatherUpdates() {
        self.shouldFetchWeather = false
    }
    
    func resumeWeatherUpdates() {
        self.shouldFetchWeather = true
        self.lastWeatherLocation = nil
    }
    
    private func fetchWeather(for location: CLLocation) -> Observable<WeatherState> {
        return Observable.create { observer in
            let task = Task {
                do {
                    let weather = try await WeatherService.shared.weather(for: location)
                    
                    let hourly = Array(weather.hourlyForecast.filter({ $0.date > Date() }).prefix(2))
                    
                    observer.onNext(WeatherState(
                        temperature: Int(weather.currentWeather.temperature.converted(to: .celsius).value),
                        currentWeather: weather.currentWeather.condition,
                        hourlyWeather: hourly
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
