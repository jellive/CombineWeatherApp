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

import SwiftUI
import Combine

class WeeklyWeatherViewModel: ObservableObject, Identifiable {
  @Published var city: String = ""
  
  @Published var dataSource: [DailyWeatherRowViewModel] = []
  
  private let weatherFetcher: WeatherFetchable
  
  private var disposables = Set<AnyCancellable>() /// 그냥 Cancellable로 하면 Scene이 사라져도 스트림은 남아있다. AnyCancellable로 하면 deinit시 같이 사라짐.  Cancellable은 JS의 PromiseLike형이라고 보면 됨.
  
  init(weatherFetcher: WeatherFetchable, scheduler: DispatchQueue = DispatchQueue(label: "WeatherViewModel")) {
    self.weatherFetcher = weatherFetcher
    
    
    /** original code
     _ = $city
     .dropFirst(1)
     .debounce(for: .seconds(0.5), scheduler: scheduler)
     .sink(receiveValue: fetchWeather(forCity:))
     */
    /// modified code
    $city /// $가 붙으면 값을 @Published, @State등을 수정가능하게 Binding하여 사용할 수 있다. 양방향 바인딩이라 생각하면 됨.
      .dropFirst() /// array에 있는 메소드, 인자값을 넣어서 해당부분까지 제거 가능.
      .debounce(for: .seconds(0.5), scheduler: scheduler) /// 0.5초마다 scheduler 실행. 여기서는 weatherfetcher를 세션으로하는 친구를 실행한다.
      .sink(receiveValue: fetchWeather(forCity:)) /// 구독 시작 후 받은 데이터를 fetchWeather로 처리하고
      .store(in: &disposables) /// disposables에 저장한다.
  }
  
  func fetchWeather(forCity city: String) {
    weatherFetcher.weeklyWeatherForecast(forCity: city)
      .map {response in
        response.list.map(DailyWeatherRowViewModel.init) /// 형변환
      }
      .map(Array.removeDuplicates)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: {
        [weak self] value in
        guard let self = self else {return}
        switch value {
        case .failure: /// Promise.reject
          self.dataSource = []
        case .finished: /// Promise.then
          break
        }
      }, receiveValue: {[weak self] forecast in
        guard let self = self else {return}
        self.dataSource = forecast
      })
      .store(in: &disposables)
  }
}

extension WeeklyWeatherViewModel {
  var currentWeatherView: some View {
    return WeeklyWeatherBuilder.makeCurrentWeatherView(withCity: city, weatherFetcher: weatherFetcher)
  }
}
