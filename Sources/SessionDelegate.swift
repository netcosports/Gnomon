import Foundation

internal func configuration(with policy: NSURLRequest.CachePolicy) -> URLSessionConfiguration {
  let configuration = URLSessionConfiguration.default
  configuration.requestCachePolicy = policy
  return configuration
}

internal class SessionDelegate: NSObject, URLSessionDataDelegate {

  internal var dataTaskWillCacheResponse: ((_ session: URLSession, _ dataTask: URLSessionDataTask,
  _ proposedResponse: CachedURLResponse) -> CachedURLResponse?)?
  internal var dataTaskDidCompletedWithData: ((_ session: URLSession, _ task: URLSessionTask,
  _ data: Data, _ response: HTTPURLResponse) -> Void)?
  internal var dataTaskDidCompletedWithError: ((_ session: URLSession, _ dataTask: URLSessionTask,
  _ error: Error) -> Void)?

  internal var authenticationChallenge: AuthenticationChallenge?

  private var response: URLResponse?
  private var data = Data()

  public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if let authenticationChallenge = authenticationChallenge {
      authenticationChallenge(challenge, completionHandler)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                  completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    self.response = response
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse cached: CachedURLResponse,
                  completionHandler: @escaping (CachedURLResponse?) -> Void) {
    if let response = cached.response as? HTTPURLResponse, let updated = response.httpCachedResponse {
      let newCached = CachedURLResponse(response: updated, data: cached.data, userInfo: cached.userInfo,
                                        storagePolicy: cached.storagePolicy)
      completionHandler(newCached)
    } else {
      completionHandler(cached)
    }
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    data.enumerateBytes { bytes, _, _ in
      self.data.append(bytes)
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      dataTaskDidCompletedWithError?(session, task, error)
    } else {
      guard let response = response else {
        dataTaskDidCompletedWithError?(session, task, Gnomon.Error.undefined(message: nil))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        dataTaskDidCompletedWithError?(session, task, Gnomon.Error.nonHTTPResponse(response: response))
        return
      }

      guard (200..<400) ~= httpResponse.statusCode else {
        dataTaskDidCompletedWithError?(session, task,
                                       Gnomon.Error.errorStatusCode(httpResponse.statusCode, data))
        return
      }

      dataTaskDidCompletedWithData?(session, task, data, httpResponse)
    }
  }

}
