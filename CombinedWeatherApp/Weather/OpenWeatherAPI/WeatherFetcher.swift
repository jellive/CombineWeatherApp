/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Combine

protocol WeatherFetchable {
  /// 프로토콜 선언. 프로토콜은 interface라 보면 됨.
  
  /// Publisher는 Just, Empty, AnyPublisher 등이 있으며, 시간이 지남에 따라 값의 시퀀스를 전달할 수 있다. event-driven임. RxSwift에는 비슷한 친구로 Observable가 있다.
  /// AnyPublisher는 타입을 지운 Publisher이다.
  func weeklyWeatherForecast (
    forCity city: String
  ) -> AnyPublisher<WeeklyForecastResponse, WeatherError>
  
  func currentWeatherForecast (
    forCity city: String
  ) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError>
}


class WeatherFetcher {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
}

// MARK: - WeatherFetchable
extension WeatherFetcher: WeatherFetchable {
  /// implement.
  func weeklyWeatherForecast(forCity city: String) -> AnyPublisher<WeeklyForecastResponse, WeatherError> {
    return forecast(with: makeWeeklyForecastComponents(withCity: city))
  }
  
  func currentWeatherForecast(forCity city: String) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError> {
    return forecast(with: makeCurrentDayForecastComponents(withCity: city))
  }
  
  private func forecast<T> (with components: URLComponents) -> AnyPublisher<T, WeatherError> where T: Decodable {
    guard let url = components.url else {
      let error = WeatherError.network(description: "Couldn't create URL")
      return Fail(error: error).eraseToAnyPublisher()
    }
    
    return session.dataTaskPublisher(for: URLRequest(url: url))
      .mapError { error in
        .network(description: error.localizedDescription)
      }
      .flatMap(maxPublishers: .max(1)) {pair in
        decode(pair.data)
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - OpenWeatherMap API
private extension WeatherFetcher {
  /// extension:  Obj-C의 category와 유사함. 차이점은 extension이 이름을 가지지 않는다는 점.
  // 다음은 예시.
  //  private extension Double {
  //    var km: Double { return self * 1_000.0 }
  //    var m: Double { return self }
  //    var cm: Double { return self / 100.0 }
  //    var mm: Double { return self / 1_000.0 }
  //
  //  }
  //  extension Rect {
  //    init(center: Point, size: Size) {
  //      let originX = center.x - (size.width / 2)
  //      let originY = center.y - (size.height / 2)
  //      self.init(origin: Point(x: originX, y: originY), size: size)
  //    }
  //  }
  //  extension Int {
  //    enum Kind {
  //      case Negative, Zero, Positive
  //    }
  //    var kind: Kind {
  //      switch self {
  //      case 0:
  //        return .Zero
  //      case let x where x > 0:
  //        return .Positive
  //      default:
  //        return .Negative
  //      }
  //    }
  //  }
  //
  //  print(0.kind)
  
  
  struct OpenWeatherAPI {
    static let scheme = "https"
    static let host = "api.openweathermap.org"
    static let path = "/data/2.5"
    static let key = "<key>"
  }
  
  func makeWeeklyForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/forecast"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
  
  func makeCurrentDayForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/weather"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
}
