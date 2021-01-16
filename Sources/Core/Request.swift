//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import RxSwift

public typealias AuthenticationChallenge = (URLAuthenticationChallenge,
                                            (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void

public enum Method: CustomStringConvertible {

  case GET, HEAD, POST, PUT, PATCH, DELETE
  case custom(String, hasBody: Bool)

  public var hasBody: Bool {
    switch self {
    case .GET, .HEAD: return false
    case .DELETE, .PATCH, .POST, .PUT: return true
    case let .custom(_, hasBody): return hasBody
    }
  }

  public var description: String {
    switch self {
    case .GET: return "GET"
    case .HEAD: return "HEAD"
    case .POST: return "POST"
    case .PUT: return "PUT"
    case .PATCH: return "PATCH"
    case .DELETE: return "DELETE"
    case let .custom(method, _): return method
    }
  }

}

public enum RequestParams {

  case none
  case skipURLEncoding
  case query([String: Any])
  case urlEncoded([String: Any])
  case json([String: Any])
  case multipart([String: String], [String: MultipartFile])
  case data(Data, contentType: String)
}

public enum LoggingPolicy {
  case never
  case always
  case onError
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

  public init(url: URL) {
    self.url = url
  }

  public convenience init(URLString: String) throws {
    guard let url = URL(string: URLString) else { throw "invalid url \"\(URLString)\"" }
    self.init(url: url)
  }

  public var xpath: String?
  public var method = Method.GET
  public var params = RequestParams.none
  public var headers: [String: String]?

  public var disableLocalCache: Bool = false
  public var disableHttpCache: Bool = false

  public var shouldHandleCookies: Bool = false

  @available(*, deprecated, message: "use asyncInterceptor instead")
  public var interceptor: Interceptor?
  public var asyncInterceptor: AsyncInterceptor?
  public var isInterceptorExclusive: Bool = false

  public var authenticationChallenge: AuthenticationChallenge?

  public var timeout: TimeInterval = 60

  public var loggingPolicy: LoggingPolicy = .never

  public var response: ((Response<Model>) -> Void)?

  public var dispatchQoS: DispatchQoS = .userInitiated

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

  @available(*, deprecated, message: "use Request.init(URLString:) instead of setURLString")
  @discardableResult
  func setURLString(_ value: String) -> IntermediateRequest { return self }

  @discardableResult
  func setXPath(_ value: String?) -> IntermediateRequest {
    xpath = value
    return self
  }

  @discardableResult
  func setMethod(_ value: Method) -> IntermediateRequest {
    method = value
    return self
  }

  @available(*, deprecated, message: "use setParams(.urlEncoded([:])) method")
  @discardableResult
  func setParams(_ value: [String: Any]?) -> IntermediateRequest {
    return self
  }

  @discardableResult
  func setParams(_ value: RequestParams) -> IntermediateRequest {
    params = value
    return self
  }

  @discardableResult
  func setHeaders(_ value: [String: String]?) -> IntermediateRequest {
    headers = value
    return self
  }

  @discardableResult
  func setDisableLocalCache(_ value: Bool) -> IntermediateRequest {
    disableLocalCache = value
    return self
  }

  @discardableResult
  func setDisableHttpCache(_ value: Bool) -> IntermediateRequest {
    disableHttpCache = value
    return self
  }

  @discardableResult
  func setDisableCache(_ value: Bool) -> IntermediateRequest {
    disableLocalCache = value
    disableHttpCache = value
    return self
  }

  @discardableResult
  func setShouldHandleCookies(_ value: Bool) -> IntermediateRequest {
    shouldHandleCookies = value
    return self
  }

  @discardableResult
  func setInterceptor(_ value: @escaping Interceptor, exclusive: Bool) -> IntermediateRequest {
    interceptor = value
    isInterceptorExclusive = exclusive
    return self
  }

  @discardableResult
  func setAsyncInterceptor(_ exclusive: Bool = false, value: @escaping AsyncInterceptor) -> IntermediateRequest {
    asyncInterceptor = value
    isInterceptorExclusive = exclusive
    return self
  }

  @discardableResult
  func setAuthenticationChallenge(_ value: @escaping AuthenticationChallenge) -> IntermediateRequest {
    authenticationChallenge = value
    return self
  }

  @discardableResult
  func setTimeout(_ value: TimeInterval) -> IntermediateRequest {
    timeout = value
    return self
  }

  @discardableResult
  func setLoggingPolicy(_ value: LoggingPolicy) -> IntermediateRequest {
    loggingPolicy = value
    return self
  }

	@available(*, deprecated, message: "use setLoggingPolicy(_ value: LoggingPolicy) method")
	@discardableResult
	func setDebugLogging(_ value: Bool) -> IntermediateRequest {
		loggingPolicy = value ? .always : .never
		return self
	}

  @discardableResult
  func setDispatchQoS(_ value: DispatchQoS) -> IntermediateRequest {
    dispatchQoS = value
    return self
  }

}

@available(*, deprecated, message: "use Request.init(URLString:) instead of RequestBuilder")
public struct RequestBuilder<Model: BaseModel> {

  public typealias Builder = RequestBuilder<Model>

  public init() {}

}
