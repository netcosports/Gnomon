//
//  Created by Vladimir Burdukov on 5/17/16.
//  Copyright © 2016 NetcoSports. All rights reserved.
//

import Foundation
import RxSwift

func configuration(with policy: NSURLRequest.CachePolicy) -> URLSessionConfiguration {
  let configuration = URLSessionConfiguration.default
  configuration.requestCachePolicy = policy
  return configuration
}

protocol SessionDelegateProtocol: URLSessionDelegate {

  var result: Observable<(Data, HTTPURLResponse)> { get }
  var authenticationChallenge: AuthenticationChallenge? { get set }

}

final class SessionDelegate: NSObject, URLSessionDataDelegate, SessionDelegateProtocol {

  fileprivate let subject = PublishSubject<(Data, HTTPURLResponse)>()
  var result: Observable<(Data, HTTPURLResponse)> { return subject }

  var authenticationChallenge: AuthenticationChallenge?

  private var response: URLResponse?
  private var data = Data()

  func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
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
    if response.expectedContentLength > 0 {
      data.reserveCapacity(Int(response.expectedContentLength))
    }

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
    data.enumerateBytes { bytes, index, _ in
      self.data.insert(contentsOf: bytes, at: index)
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      subject.onError(error)
    } else {
      guard let response = response else {
        subject.onError(Gnomon.Error.undefined(message: nil))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        subject.onError(Gnomon.Error.nonHTTPResponse(response: response))
        return
      }

      subject.onNext((data, httpResponse))
    }
  }

}
