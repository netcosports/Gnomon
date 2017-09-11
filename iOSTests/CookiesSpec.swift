//
// Created by Vladimir Burdukov on 18/5/17.
// Copyright (c) 2017 NetcoSports. All rights reserved.
//

import XCTest
import Nimble
import RxSwift
import RxBlocking
import SwiftyJSON

@testable import Gnomon

class CookieSpec: XCTestCase {

  override func setUp() {
    super.setUp()

    Nimble.AsyncDefaults.Timeout = 7
    URLCache.shared.removeAllCachedResponses()

    let urlString = "\(Params.API.baseURL)/cookies"
    guard let url = URL(string: urlString) else { return fail() }
    for cookie in HTTPCookieStorage.shared.cookies(for: url) ?? [] {
      HTTPCookieStorage.shared.deleteCookie(cookie)
    }
  }

  override func tearDown() {
    super.tearDown()

    let urlString = "\(Params.API.baseURL)/cookies"
    guard let url = URL(string: urlString) else { return fail() }
    for cookie in HTTPCookieStorage.shared.cookies(for: url) ?? [] {
      HTTPCookieStorage.shared.deleteCookie(cookie)
    }
  }

  func testShouldIgnoreIncomingCookiesByDefault() {
    let request: Request<SingleResult<String>>
    do {
      let builder = RequestBuilder<SingleResult<String>>()
        .setURLString("\(Params.API.baseURL)/cookies/set?dont_send_me_cookie=true").setMethod(.GET)
      request = try builder.build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.characters.count).to(beGreaterThan(0))

      let urlString = "\(Params.API.baseURL)/cookies"
      guard let url = URL(string: urlString) else { return fail() }
      expect(HTTPCookieStorage.shared.cookies(for: url)).to(haveCount(0))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testShouldNotSendLocalCookiesByDefault() {
    do {
      let urlString = "\(Params.API.baseURL)/cookies"
      guard let url = URL(string: urlString) else { return fail() }

      for cookie in HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": "dont_send_me_cookie=true; Path=/"],
                                       for: url) {
        HTTPCookieStorage.shared.setCookie(cookie)
      }

      struct CookiesModel: JSONModel {

        let cookies: [String: String]

        init(_ json: JSON) throws {
          cookies = json["cookies"].dictionaryValue.reduce([:]) { (result, tuple) in
            var result = result
            result[tuple.key] = tuple.value.stringValue
            return result
          }
        }

      }

      let builder = RequestBuilder<SingleResult<CookiesModel>>()
        .setURLString(urlString).setMethod(.GET)
      let request = try builder.build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.cookies).to(beEmpty())
    } catch {
      fail("\(error)")
      return
    }
  }

  func testShouldHandleIncomingCookiesIfRequested() {
    let request: Request<SingleResult<String>>
    do {
      let builder = RequestBuilder<SingleResult<String>>()
        .setURLString("\(Params.API.baseURL)/cookies/set?dont_send_me_cookie=true").setMethod(.GET)
        .setShouldHandleCookies(true)
      request = try builder.build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.characters.count).to(beGreaterThan(0))

      let urlString = "\(Params.API.baseURL)/cookies"
      guard let url = URL(string: urlString) else { return fail() }

      guard let receivedCookies = HTTPCookieStorage.shared.cookies(for: url) else { return fail() }
      expect(receivedCookies).to(haveCount(1))

      expect(receivedCookies[0].name).to(equal("dont_send_me_cookie"))
      expect(receivedCookies[0].value).to(equal("true"))
    } catch {
      fail("\(error)")
      return
    }
  }

  func testShouldSendLocalCookiesIfRequested() {
    do {
      let urlString = "\(Params.API.baseURL)/cookies"
      guard let url = URL(string: urlString) else { return fail() }

      for cookie in HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": "dont_send_me_cookie=true; Path=/"],
                                       for: url) {
        HTTPCookieStorage.shared.setCookie(cookie)
      }

      struct CookiesModel: JSONModel {

        let cookies: [String: String]

        init(_ json: JSON) throws {
          cookies = json["cookies"].dictionaryValue.reduce([:]) { (result, tuple) in
            var result = result
            result[tuple.key] = tuple.value.stringValue
            return result
          }
        }

      }

      let builder = RequestBuilder<SingleResult<CookiesModel>>()
        .setURLString(urlString).setMethod(.GET).setShouldHandleCookies(true)
      let request = try builder.build()

      let response = try Gnomon.models(for: request).toBlocking().first()
      expect(response).toNot(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      expect(result.model.cookies).to(equal(["dont_send_me_cookie": "true"]))
    } catch {
      fail("\(error)")
      return
    }
  }

}
