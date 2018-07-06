//
//  CertificateSpec.swift
//  Tests
//
//  Created by Vladimir Burdukov on 27/8/17.
//
//

import XCTest
import Gnomon
import Nimble
import RxBlocking

class CertificateSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()
    Gnomon.removeAllInterceptors()
  }

  func testInvalidCertificate() {
    do {
      let request = try Request<String>(URLString: "https://self-signed.badssl.com/").setMethod(.GET)
      request.authenticationChallenge = { challenge, completionHandler -> Void in
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
      }

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      expect(response.result.count).to(beGreaterThan(0))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testInvalidCertificateWithoutHandler() {
    do {
      let request = try Request<String>(URLString: "https://self-signed.badssl.com/").setMethod(.GET)
      let result = try Gnomon.models(for: request).toBlocking().first()
      expect(result).to(beNil())
    } catch let error as NSError {
      expect(error.domain) == NSURLErrorDomain
      expect(error.code) == NSURLErrorServerCertificateUntrusted
    } catch {
      fail("\(error)")
    }
  }

}
