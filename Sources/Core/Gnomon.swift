//
//  Created by Vladimir Burdukov on 7/6/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import RxSwift
import FormatterKit

public class Gnomon {

  // MARK: - Public

  fileprivate static var interceptors: [Interceptor] = []

  public class func addRequestInterceptor(_ interceptor: @escaping Interceptor) {
    interceptors.append(interceptor)
  }

  public class func removeAllInterceptors() {
    interceptors.removeAll()
  }

  public class func models<U>(for request: Request<U>) -> Observable<Response<U>> {
    do {
      return try observable(for: request, inLocalCache: false).flatMap { data, response -> Observable<Response<U>> in
        let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
        return try parse(data: data, response: response, responseType: type, for: request)
          .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      }
    } catch {
      return .error(error)
    }
  }

  public class func models<U: NonOptionalResult>(for requests: [Request<U>]) -> Observable<[Response<U>]> {
    guard requests.count > 0 else { return .just([]) }
    return Observable.zip(requests.map { models(for: $0) })
  }

  public class func models<U: OptionalResult>(for requests: [Request<U>]) -> Observable<[Response<U>]> {
    guard requests.count > 0 else { return .just([]) }
    return Observable.zip(requests.map {
      models(for: $0).catchErrorJustReturn(Response.empty(with: .regular))
    })
  }

  public class func cachedModels<U: OptionalResult>(for request: Request<U>) -> Observable<Response<U>> {
    do {
      return try observable(for: request, inLocalCache: true).flatMap { data, response -> Observable<Response<U>> in
        return try parse(data: data, response: response, responseType: .localCache, for: request)
          .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        }.catchErrorJustReturn(Response.empty(with: .localCache))
    } catch {
      return .error(error)
    }
  }

  public class func cachedModels<U: OptionalResult>(for requests: [Request<U>]) -> Observable<[Response<U>]> {
    guard requests.count > 0 else { return .just([]) }
    return Observable.zip(requests.map { cachedModels(for: $0) })
  }

  public class func cachedThenFetch<U: OptionalResult>(_ request: Request<U>) -> Observable<Response<U>> {
    return cachedModels(for: request).concat(models(for: request))
  }

  public class func cachedThenFetch<U: OptionalResult>(_ requests: [Request<U>]) -> Observable<[Response<U>]> {
    return cachedModels(for: requests).concat(models(for: requests))
  }

  // MARK: - Private

  private class func observable<U>(for request: Request<U>, inLocalCache localCache: Bool)
  throws -> Observable<(Data, HTTPURLResponse)> {
    return Observable.deferred {
      let delegate = SessionDelegate()
      delegate.authenticationChallenge = request.authenticationChallenge

      let cachePolicy: URLRequest.CachePolicy
      if localCache {
        guard !request.disableLocalCache else { throw "local cache was disabled in request" }
        cachePolicy = .returnCacheDataDontLoad
      } else {
        cachePolicy = request.disableHttpCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
      }

      let session = URLSession(configuration: configuration(with: cachePolicy), delegate: delegate, delegateQueue: nil)
      var dataRequest = try prepareDataRequest(from: request, cachePolicy: cachePolicy)
      if let interceptor = request.interceptor {
        if request.isInterceptorExclusive {
          dataRequest = interceptor(dataRequest)
        } else {
          dataRequest = interceptor(dataRequest)
          dataRequest = interceptors.reduce(dataRequest) { $1($0) }
        }
      } else {
        dataRequest = interceptors.reduce(dataRequest) { $1($0) }
      }

      curlLog(request, dataRequest)

      let task = Observable<(Data, HTTPURLResponse)>.create { [weak delegate] subscriber -> Disposable in
        let task = session.dataTask(with: dataRequest)

        delegate?.dataTaskDidCompletedWithData = { _, _, data, response in
          subscriber.onNext((data, response))
          subscriber.onCompleted()
        }
        delegate?.dataTaskDidCompletedWithError = { subscriber.onError($2) }

        task.resume()
        session.finishTasksAndInvalidate()

        if #available(iOS 10.0, *) {
          return Disposables.create { [weak task] in
            if task?.state == .running {
              task?.cancel()
            }
          }
        } else {
          return Disposables.create()
        }
      }

      return task
    }
  }

  private class func parse<U>(data: Data, response httpResponse: HTTPURLResponse, responseType: ResponseType,
                              for request: Request<U>)
  throws -> Observable<Response<U>> {
    return Observable.create { subscriber -> Disposable in
      let result: U
      do {
        result = try processedResult(from: data, for: request)
      } catch {
        subscriber.onError(error)
        return Disposables.create()
      }

      let headers: [String: String]
      if let _headers = httpResponse.allHeaderFields as? [String: String] {
        headers = _headers
      } else {
        headers = [:]
      }

      let response = Response(result: result, responseType: responseType, headers: headers,
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

  internal static var log: (String) -> Void = { string in
    print(string)
  }

}
