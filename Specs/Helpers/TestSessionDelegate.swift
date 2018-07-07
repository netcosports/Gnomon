//
// Created by Vladimir Burdukov on 06/07/2018.
//

import RxSwift
@testable import Gnomon

class TestSessionDelegate: NSObject, SessionDelegateProtocol {

  let result: Observable<(Data, HTTPURLResponse)>

  init(_ testResult: Observable<(Data, HTTPURLResponse)>) {
    self.result = testResult
    super.init()
  }

  var authenticationChallenge: AuthenticationChallenge? = nil
  private static let url = URL(string: "https://example.com/")!

  private static func response(statusCode: Int) -> HTTPURLResponse {
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
  }

  static func jsonResponse(result: Any, statusCode: Int = 200, cached: Bool,
                           delay: TimeInterval = 0) throws -> TestSessionDelegate {
    let data = try JSONSerialization.data(withJSONObject: result)
    var response = self.response(statusCode: statusCode)

    if cached {
      response = response.httpCachedResponse!
    }

    return TestSessionDelegate(Observable.just((data, response))
                                 .delay(delay, scheduler: ConcurrentDispatchQueueScheduler(qos: .background)))
  }

  static func stringResponse(result: String, statusCode: Int = 200, cached: Bool) throws -> TestSessionDelegate {
    guard let data = result.data(using: .utf8) else { throw "can't create utf8 data from string \"\(result)\"" }
    var response = self.response(statusCode: statusCode)

    if cached {
      response = response.httpCachedResponse!
    }

    return TestSessionDelegate(Observable.just((data, response)))
  }

  static func noCacheResponse() -> TestSessionDelegate {
    return TestSessionDelegate(Observable.error(NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable)))
  }

}
