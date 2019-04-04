//
//  Created by Vladimir Burdukov on 7/6/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import RxSwift
import FormatterKit

public enum Gnomon {

  fileprivate static var interceptors: [Interceptor] = []

  public static func addRequestInterceptor(_ interceptor: @escaping Interceptor) {
    interceptors.append(interceptor)
  }

  public static func removeAllInterceptors() {
    interceptors.removeAll()
  }

  public static func models<U>(for request: Request<U>) -> Observable<Response<U>> {
    do {
      return try observable(for: request, localCache: false).flatMap { data, response -> Observable<Response<U>> in
        let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
        return try parse(data: data, response: response, responseType: type, for: request)
          .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
      }
    } catch {
      return .error(error)
    }
  }

  public static func cachedModels<U>(for request: Request<U>) -> Observable<Response<U>> {
    return cachedModels(for: request, catchErrors: true)
  }

  private static func cachedModels<U>(for request: Request<U>, catchErrors: Bool) -> Observable<Response<U>> {
    do {
      let result = try observable(for: request, localCache: true).flatMap { data, response in
        return try parse(data: data, response: response, responseType: .localCache, for: request)
          .subscribeOn(ConcurrentDispatchQueueScheduler(qos: . userInitiated))
      }

      if catchErrors {
        return result.catchError { _ in return Observable<Response<U>>.empty() }
      } else {
        return result
      }
    } catch {
      return .error(error)
    }
  }

  public static func cachedThenFetch<U>(_ request: Request<U>) -> Observable<Response<U>> {
    return cachedModels(for: request).concat(models(for: request))
  }

  public static func cachedModels<U>(for requests: [Request<U>]) -> Observable<[Result<Response<U>, Swift.Error>]> {
    guard !requests.isEmpty else { return .just([]) }

    return Observable.combineLatest(requests.map { request in
      cachedModels(for: request, catchErrors: false).asResult()
    })
  }

  public static func models<U>(for requests: [Request<U>]) -> Observable<[Result<Response<U>, Swift.Error>]> {
    guard !requests.isEmpty else { return .just([]) }

    return Observable.combineLatest(requests.map { request in
      models(for: request).asResult()
    })
  }

  public static func cachedThenFetch<U>(_ requests: [Request<U>]) -> Observable<[Result<Response<U>, Swift.Error>]> {
    guard !requests.isEmpty else { return .just([]) }

    let cached = requests.map { cachedModels(for: $0, catchErrors: true).asResult() }
    let http = requests.map { models(for: $0).asResult() }

    return Observable.zip(cached).filter { results in
      return results.filter { $0.value != nil }.count == requests.count
    }.concat(Observable.zip(http))
  }

  private static func observable<U>(for request: Request<U>,
                                    localCache: Bool) throws -> Observable<(Data, HTTPURLResponse)> {
    return Observable.deferred {
      #if TEST
      let delegate = localCache ? request.cacheSessionDelegate : request.httpSessionDelegate
      #else
      let delegate = SessionDelegate()
      #endif

      delegate.authenticationChallenge = request.authenticationChallenge

      let policy = try cachePolicy(for: request, localCache: localCache)
      let session = URLSession(configuration: configuration(with: policy), delegate: delegate, delegateQueue: nil)

      let urlRequest = try prepareURLRequest(from: request, cachePolicy: policy, interceptors: interceptors)

      curlLog(request, urlRequest)

      let result = delegate.result.take(1).map { tuple -> (Data, HTTPURLResponse) in
        let (data, response) = tuple

        guard (200 ..< 400) ~= response.statusCode else {
          throw Gnomon.Error.errorStatusCode(response.statusCode, data)
        }

        return tuple
      }

      #if TEST
      guard request.shouldRunTask else { return result }
      #endif

      let task = session.dataTask(with: urlRequest)
      task.resume()
      session.finishTasksAndInvalidate()

      return result.do(onDispose: {
        if #available(iOS 10.0, *) {
          if task.state == .running {
            task.cancel()
          }
        }
      })
    }
  }

  private static func parse<U>(data: Data, response httpResponse: HTTPURLResponse, responseType: ResponseType,
                               for request: Request<U>) throws -> Observable<Response<U>> {
    return Observable.create { subscriber -> Disposable in
      let result: U
      do {
        let container = try U.dataContainer(with: data, at: request.xpath)
        result = try U(container)
      } catch {
        subscriber.onError(error)
        return Disposables.create()
      }

      let headers: [String: String]
      if let responseHeaders = httpResponse.allHeaderFields as? [String: String] {
        headers = responseHeaders
      } else {
        headers = [:]
      }

      let response = Response(result: result, type: responseType, headers: headers,
                              statusCode: httpResponse.statusCode)
      request.response?(response)
      subscriber.onNext(response)
      subscriber.onCompleted()

      return Disposables.create()
    }
  }

  // MARK: - Logging

  public static var logging = false

  private static func curlLog<U>(_ request: Request<U>, _ dataRequest: URLRequest) {
    if let debugLogging = request.debugLogging, !debugLogging { return }
    debugLog(TTTURLRequestFormatter.cURLCommand(from: dataRequest), request.debugLogging ?? false)
  }

  internal static var debugLog: (String, Bool) -> Void = { string, force in
    if logging || force {
      log(string)
    }
  }

  internal static var errorLog: (String) -> Void = { string in
    log(string)
  }

  public static var log: (String) -> Void = { string in
    print(string)
  }

}
