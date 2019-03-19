//
//  Created by Vladimir Burdukov on 7/6/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import RxSwift

extension String: Error {
}

@available(*, deprecated, renamed: "Gnomon.Error")
public enum CommonError: Swift.Error {
  case none
}

public extension Gnomon {

  enum Error: Swift.Error {
    case undefined(message: String?)
    case nonHTTPResponse(response: URLResponse)
    case invalidResponse
    case unableToParseModel(Swift.Error)
    case errorStatusCode(Int, Data)
  }

}

extension HTTPURLResponse {

  private static var cacheFlagKey = "X-ResultFromHttpCache"

  var httpCachedResponse: HTTPURLResponse? {
    guard let url = url else { return nil }
    var headers = allHeaderFields as? [String: String] ?? [:]
    headers[HTTPURLResponse.cacheFlagKey] = "true"
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
  }

  var resultFromHTTPCache: Bool {
    guard let headers = allHeaderFields as? [String: String] else { return false }
    return headers[HTTPURLResponse.cacheFlagKey] == "true"
  }

}

func cachePolicy<U>(for request: Request<U>, localCache: Bool) throws -> URLRequest.CachePolicy {
  if localCache {
    guard !request.disableLocalCache else { throw "local cache was disabled in request" }
    return .returnCacheDataDontLoad
  } else {
    return request.disableHttpCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
  }
}

func prepareURLRequest<U>(from request: Request<U>, cachePolicy: URLRequest.CachePolicy,
                          interceptors: [Interceptor]) throws -> URLRequest {
  var urlRequest = URLRequest(url: request.url, cachePolicy: cachePolicy, timeoutInterval: request.timeout)
  urlRequest.httpMethod = request.method.description
  if let headers = request.headers {
    for (key, value) in headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }
  }

  switch (request.method.hasBody, request.params) {
  case (_, .skipURLEncoding):
    urlRequest.url = request.url
  case (_, .none):
    urlRequest.url = try prepareURL(with: request.url, params: nil)
  case let (_, .query(params)):
    urlRequest.url = try prepareURL(with: request.url, params: params)
  case (false, _):
    throw "\(request.method.description) request can't have a body"
  case (true, let .urlEncoded(params)):
    let queryItems = prepare(value: params, with: nil)
    var components = URLComponents()
    components.queryItems = queryItems
    urlRequest.httpBody = components.percentEncodedQuery?.data(using: String.Encoding.utf8)
    urlRequest.url = try prepareURL(with: request.url, params: nil)
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
  case (true, let .json(params)):
    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: request.url, params: nil)
  case (true, let .multipart(form, files)):
    let (data, contentType) = try prepareMultipartData(with: form, files)
    urlRequest.httpBody = data
    urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: request.url, params: nil)
  case (true, let .data(data, contentType)):
    urlRequest.httpBody = data
    urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: request.url, params: nil)
  }

  urlRequest.httpShouldHandleCookies = request.shouldHandleCookies

  return process(urlRequest, for: request, with: interceptors)
}

private func process<U>(_ urlRequest: URLRequest, for request: Request<U>,
                        with interceptors: [Interceptor]) -> URLRequest {
  if let interceptor = request.interceptor {
    if request.isInterceptorExclusive {
      return interceptor(urlRequest)
    } else {
      var urlRequest = urlRequest
      urlRequest = interceptor(urlRequest)
      urlRequest = interceptors.reduce(urlRequest) { $1($0) }
      return urlRequest
    }
  } else {
    return interceptors.reduce(urlRequest) { $1($0) }
  }
}

func prepareURL(with url: URL, params: [String: Any]?) throws -> URL {
  var queryItems = [URLQueryItem]()
  if let params = params {
    queryItems.append(contentsOf: prepare(value: params, with: nil))
  }

  guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
    throw "can't parse provided URL \"\(url)\""
  }

  queryItems.append(contentsOf: components.queryItems ?? [])
  components.queryItems = queryItems.count > 0 ? queryItems : nil
  guard let url = components.url else { throw "can't prepare URL from components: \(components)" }
  return url
}

private func prepare(value: Any, with key: String?) -> [URLQueryItem] {
  switch value {
  case let dictionary as [String: Any]:
    return dictionary.sorted { $0.0 < $1.0 }.flatMap { nestedKey, nestedValue -> [URLQueryItem] in
      if let key = key {
        return prepare(value: nestedValue, with: "\(key)[\(nestedKey)]")
      } else {
        return prepare(value: nestedValue, with: nestedKey)
      }
    }
  case let array as [Any]:
    if let key = key {
      return array.flatMap { prepare(value: $0, with: "\(key)[]") }
    } else {
      return []
    }
  case let string as String:
    if let key = key {
      return [URLQueryItem(name: key, value: string)]
    } else {
      return []
    }
  case let stringConvertible as CustomStringConvertible:
    if let key = key {
      return [URLQueryItem(name: key, value: stringConvertible.description)]
    } else {
      return []
    }
  default: return []
  }
}

func prepareMultipartData(with form: [String: String],
                          _ files: [String: MultipartFile]) throws -> (data: Data, contentType: String) {
  let boundary = "__X_NST_BOUNDARY__"
  var data = Data()
  guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8) else { throw "can't encode boundary" }
  for (key, value) in form {
    data.append(boundaryData)
    guard let dispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) else {
      throw "can't encode key \(key)"
    }
    data.append(dispositionData)
    guard let valueData = (value + "\r\n").data(using: .utf8) else { throw "can't encode value \(value)" }
    data.append(valueData)
  }

  for (key, file) in files {
    data.append(boundaryData)
    guard let dispositionData = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n"
      .data(using: .utf8) else { throw "can't encode key \(key)" }
    data.append(dispositionData)
    guard let contentTypeData = "Content-Type: \(file.contentType)\r\n\r\n".data(using: .utf8) else {
      throw "can't encode content-type \(file.contentType)"
    }
    data.append(contentTypeData)
    data.append(file.data)
    guard let carriageReturnData = "\r\n".data(using: .utf8) else {
      throw "can't encode carriage return"
    }
    data.append(carriageReturnData)
  }

  guard let closingBoundaryData = "--\(boundary)--\r\n".data(using: .utf8) else {
    throw "can't encode closing boundary"
  }
  data.append(closingBoundaryData)
  return (data, "multipart/form-data; boundary=\(boundary)")
}

func processedResult<U>(from data: Data, for request: Request<U>) throws -> U {
  let container = try U.dataContainer(with: data, at: request.xpath)
  return try U(container)
}

public typealias Interceptor = (URLRequest) -> URLRequest

public enum Result<T> {
  case ok(T)
  case error(Error)
}

public extension Result {

  var value: T? {
    switch self {
    case let .ok(value): return value
    case .error: return nil
    }
  }

  var error: Error? {
    switch self {
    case .ok: return nil
    case let .error(error): return error
    }
  }

  func map<U>(_ transform: (T) throws -> U) rethrows -> Result<U> {
    switch self {
    case let .ok(value):
      return .ok(try transform(value))
    case let .error(error):
      return .error(error)
    }
  }

  func value(or `default`: T) -> T {
    switch self {
    case let .ok(value): return value
    case .error: return `default`
    }
  }

}

extension ObservableType {

  func asResult() -> Observable<Result<E>> {
    return materialize().map { event -> Event<Result<E>> in
      switch event {
      case let .next(element): return .next(.ok(element))
      case let .error(error): return .next(.error(error))
      case .completed: return .completed
      }
    }.dematerialize()
  }

}
