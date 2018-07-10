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
  case query([String: Any])
  case urlEncoded([String: Any])
  case json([String: Any])
  case multipart([String: String], [String: MultipartFile])
  case data(Data, contentType: String)

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

public class Request<Model: BaseModel> {

  public let url: URL

  public init(URLString: String) throws {
    guard let url = URL(string: URLString) else { throw "invalid url \"\(URLString)\"" }
    self.url = url
  }

  public var xpath: String?
  public var method = Method.GET
  public var params = RequestParams.none
  public var headers: [String: String]?

  public var disableLocalCache: Bool = false
  public var disableHttpCache: Bool = false

  public var shouldHandleCookies: Bool = false

  public var interceptor: Interceptor?
  public var isInterceptorExclusive: Bool = false

  public var authenticationChallenge: AuthenticationChallenge?

  public var timeout: TimeInterval = 60

  public var debugLogging: Bool?

  public var response: ((Response<Model>) -> Void)?

  public typealias IntermediateRequest = Request<Model>

  #if TEST
  // swiftlint:disable weak_delegate
  lazy var cacheSessionDelegate: SessionDelegateProtocol = SessionDelegate()
  lazy var httpSessionDelegate: SessionDelegateProtocol = SessionDelegate()
  // swiftlint:enable weak_delegate
  var shouldRunTask = false
  #endif

}

public extension Request {

  @discardableResult
  @available(*, deprecated: 4.0, message: "use Request.init(URLString:) instead of setURLString")
  public func setURLString(_ value: String) -> IntermediateRequest { return self }

  @discardableResult
  public func setXPath(_ value: String?) -> IntermediateRequest {
    xpath = value
    return self
  }

  @discardableResult
  public func setMethod(_ value: Method) -> IntermediateRequest {
    method = value
    return self
  }

  @discardableResult
  public func setParams(_ value: [String: Any]?) -> IntermediateRequest {
    if let value = value {
      params = .urlEncoded(value)
    } else {
      params = .none
    }
    return self
  }

  @discardableResult
  public func setParams(_ value: RequestParams) -> IntermediateRequest {
    params = value
    return self
  }

  @discardableResult
  public func setHeaders(_ value: [String: String]?) -> IntermediateRequest {
    headers = value
    return self
  }

  @discardableResult
  public func setDisableLocalCache(_ value: Bool) -> IntermediateRequest {
    disableLocalCache = value
    return self
  }

  @discardableResult
  public func setDisableHttpCache(_ value: Bool) -> IntermediateRequest {
    disableHttpCache = value
    return self
  }

  @discardableResult
  public func setDisableCache(_ value: Bool) -> IntermediateRequest {
    disableLocalCache = value
    disableHttpCache = value
    return self
  }

  @discardableResult
  public func setShouldHandleCookies(_ value: Bool) -> IntermediateRequest {
    shouldHandleCookies = value
    return self
  }

  @discardableResult
  public func setInterceptor(_ value: @escaping Interceptor, exclusive: Bool) -> IntermediateRequest {
    interceptor = value
    isInterceptorExclusive = exclusive
    return self
  }

  @discardableResult
  public func setAuthenticationChallenge(_ value: @escaping AuthenticationChallenge) -> IntermediateRequest {
    authenticationChallenge = value
    return self
  }

  @discardableResult
  public func setTimeout(_ value: TimeInterval) -> IntermediateRequest {
    timeout = value
    return self
  }

  @discardableResult
  public func setDebugLogging(_ value: Bool) -> IntermediateRequest {
    debugLogging = value
    return self
  }

}

@available(*, deprecated: 4.0, message: "use Request.init(URLString:) instead of RequestBuilder")
public struct RequestBuilder<Model: BaseModel> {

  public typealias Builder = RequestBuilder<Model>

  public init() {}

}
