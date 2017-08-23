//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation

public typealias AuthenticationChallenge = (URLAuthenticationChallenge,
                                            (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void

public enum Method: String {
  case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT

  public var canHaveBody: Bool {
    switch self {
    case .GET, .HEAD, .DELETE: return false
    case .CONNECT, .OPTIONS, .PATCH, .POST, .PUT, .TRACE: return true
    }
  }

}

public enum RequestParams {

  case none
  case urlEncoded([String: Any])
  case json([String: Any])
  case multipart([String: String], [String: MultipartFile])

}

public struct MultipartFile {

  public let data: Data
  public let contentType: String
  public let filename: String

  public init(data: Data, contentType: String, filename: String) {
    self.data = data
    self.contentType = contentType
    self.filename = filename
  }

}

@available(*, unavailable, renamed: "Request")
public class PlainRequest<ResultType: Result> {

}

public class Request<ResultType: Result> {

  public typealias ModelType = ResultType.ModelType
  public fileprivate(set) var URLString: String = ""
  public fileprivate(set) var xpath: String?
  public fileprivate(set) var method = Method.GET
  public fileprivate(set) var params = RequestParams.none
  public fileprivate(set) var headers: [String: String]?

  @available(*, deprecated: 1.2.1, message: "use RequestParams enum")
  public fileprivate(set) var requestBodyAsJSON: Bool = false

  public fileprivate(set) var disableLocalCache: Bool = false
  public fileprivate(set) var disableHttpCache: Bool = false

  public fileprivate(set) var shouldHandleCookies: Bool = false

  public fileprivate(set) var interceptor: Interceptor?
  public fileprivate(set) var isInterceptorExclusive: Bool = false

  public fileprivate(set) var authenticationChallenge: AuthenticationChallenge?

  public var response: ((Response<ResultType>) -> Void)?

  fileprivate init() {}

}

@available(*, unavailable, renamed: "RequestBuilder")
public struct PlainRequestBuilder<ResultType: Result> {
}

public struct RequestBuilder<ResultType: Result> {

  private var request = Request<ResultType>()
  public typealias Builder = RequestBuilder<ResultType>

  public init() {}

  @discardableResult
  public func setURLString(_ value: String) -> Builder {
    request.URLString = value
    return self
  }

  @discardableResult
  public func setXPath(_ value: String?) -> Builder {
    request.xpath = value
    return self
  }

  @discardableResult
  public func setMethod(_ value: Method) -> Builder {
    request.method = value
    return self
  }

  @discardableResult
  public func setParams(_ value: [String: Any]?) -> Builder {
    if let value = value {
      request.params = .urlEncoded(value)
    } else {
      request.params = .none
    }
    return self
  }

  @discardableResult
  public func setParams(_ value: RequestParams) -> Builder {
    request.params = value
    return self
  }

  @discardableResult
  public func setHeaders(_ value: [String: String]?) -> Builder {
    request.headers = value
    return self
  }

  @available(*, deprecated: 1.2.1, message: "use setParams(.json([:])) method")
  @discardableResult
  public func setRequestBodyAsJSON(_ value: Bool) -> Builder {
    request.requestBodyAsJSON = value
    return self
  }

  @discardableResult
  public func setDisableLocalCache(_ value: Bool) -> Builder {
    request.disableLocalCache = value
    return self
  }

  @discardableResult
  public func setDisableHttpCache(_ value: Bool) -> Builder {
    request.disableHttpCache = value
    return self
  }

  @discardableResult
  public func setDisableCache(_ value: Bool) -> Builder {
    request.disableLocalCache = value
    request.disableHttpCache = value
    return self
  }

  @discardableResult
  public func setShouldHandleCookies(_ value: Bool) -> Builder {
    request.shouldHandleCookies = value
    return self
  }

  @discardableResult
  public func setInterceptor(_ value: @escaping Interceptor, exclusive: Bool) -> Builder {
    request.interceptor = value
    request.isInterceptorExclusive = exclusive
    return self
  }

  @discardableResult
  public func setAuthenticationChallenge(_ value: @escaping AuthenticationChallenge) -> Builder {
    request.authenticationChallenge = value
    return self
  }

  public func build() throws -> Request<ResultType> {
    try validate()
    return request
  }

  private func validate() throws {
    guard request.URLString.characters.count > 0 else {
      throw "empty URL"
    }
  }

}
