//
// Created by Vladimir Burdukov on 09/07/2018.
//

import XCTest
import Nimble

@testable import Gnomon

class URLRequestGenerationSpec: XCTestCase {

  func testValidURL() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.url) == URL(string: "https://example.com")!
    } catch {
      fail("\(error)")
    }
  }

  func testInvalidURL() {
    do {
      _ = try Request<String>(URLString: "ß")
      fail("should fail")
    } catch let error as String {
      expect(error) == "invalid url \"ß\""
    } catch {
      fail("\(error)")
    }
  }

  func testMethods() {
    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.GET)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "GET"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.HEAD)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "HEAD"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.POST)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "POST"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.PUT)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "PUT"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.PATCH)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "PATCH"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.DELETE)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "DELETE"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: true))
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "KEK"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setMethod(.custom("KEK", hasBody: false))
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpMethod) == "KEK"
    } catch {
      fail("\(error)")
    }
  }

  func testHeaders() {
    do {
      let request = try Request<String>(URLString: "https://example.com").setHeaders(["MySuperTestHeader": "kek"])
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.allHTTPHeaderFields) == ["MySuperTestHeader": "kek"]
    } catch {
      fail("\(error)")
    }
  }

  func testDisableLocalCache() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let policy = try cachePolicy(for: request, localCache: true)
      expect(policy) == .returnCacheDataDontLoad
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableLocalCache(true)
      _ = try cachePolicy(for: request, localCache: true)
      fail("should fail")
    } catch let error as String {
      expect(error) == "local cache was disabled in request"
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
      let policy = try cachePolicy(for: request, localCache: true)
      expect(policy) == .returnCacheDataDontLoad
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableCache(true)
      _ = try cachePolicy(for: request, localCache: true)
      fail("should fail")
    } catch let error as String {
      expect(error) == "local cache was disabled in request"
    } catch {
      fail("\(error)")
    }
  }

  func testDisableHttpCache() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let policy = try cachePolicy(for: request, localCache: false)
      expect(policy) == .useProtocolCachePolicy
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableLocalCache(true)
      let policy = try cachePolicy(for: request, localCache: false)
      expect(policy) == .useProtocolCachePolicy
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableHttpCache(true)
      let policy = try cachePolicy(for: request, localCache: false)
      expect(policy) == .reloadIgnoringLocalCacheData
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setDisableCache(true)
      let policy = try cachePolicy(for: request, localCache: false)
      expect(policy) == .reloadIgnoringLocalCacheData
    } catch {
      fail("\(error)")
    }
  }

  func testShouldHandleCookies() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(false)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpShouldHandleCookies).to(beFalsy())
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setShouldHandleCookies(true)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.httpShouldHandleCookies).to(beTruthy())
    } catch {
      fail("\(error)")
    }
  }

  func testGlobalInterceptor() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [
        { request in
          var request = request
          request.url = request.url.map { $0.appendingPathComponent("kek") }
          return request
        }
      ])

      expect(urlRequest.url) == URL(string: "https://example.com/kek")!
    } catch {
      fail("\(error)")
    }
  }

  func testCustomExclusiveInterceptor() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
        .setInterceptor({ request in
                          var request = request
                          request.url = URL(string: "https://kekxample.com")
                          return request
                        }, exclusive: true)

      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [
        { request in
          var request = request
          request.url = request.url.map { $0.appendingPathComponent("kek") }
          return request
        }
      ])

      expect(urlRequest.url) == URL(string: "https://kekxample.com")!
    } catch {
      fail("\(error)")
    }
  }

  func testCustomNonexclusiveInterceptor() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
        .setInterceptor({ request in
                          var request = request
                          request.url = URL(string: "https://kekxample.com")
                          return request
                        }, exclusive: false)

      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [
        { request in
          var request = request
          request.url = request.url.map { $0.appendingPathComponent("kek") }
          return request
        }
      ])

      expect(urlRequest.url) == URL(string: "https://kekxample.com/kek")!
    } catch {
      fail("\(error)")
    }
  }

  func testCustomNonexclusiveInterceptorShouldBeCalledFirst() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
        .setInterceptor({ request in
                          var request = request
                          request.url = request.url.map { $0.appendingPathComponent("lol") }
                          return request
                        }, exclusive: false)

      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [
        { request in
          var request = request
          request.url = request.url.map { $0.appendingPathComponent("kek") }
          return request
        }
      ])

      expect(urlRequest.url) == URL(string: "https://example.com/lol/kek")!
    } catch {
      fail("\(error)")
    }
  }

  func testTimeout() {
    do {
      let request = try Request<String>(URLString: "https://example.com")
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.timeoutInterval) == 60
    } catch {
      fail("\(error)")
    }

    do {
      let request = try Request<String>(URLString: "https://example.com").setTimeout(5)
      let urlRequest = try prepareURLRequest(from: request, cachePolicy: .useProtocolCachePolicy, interceptors: [])

      expect(urlRequest.timeoutInterval) == 5
    } catch {
      fail("\(error)")
    }
  }

}
