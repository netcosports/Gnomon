//
//  URLRequestFormatter.swift
//
//  Created by Eugen Filipkov on 11/12/19.
//

import Foundation

precedencegroup Additive {
  associativity: left
}

infix operator ++=: Additive
func ++= (lhs: inout String, rhs: String) {
  lhs += " \(rhs.trimmingCharacters(in: .whitespaces))"
}

public class URLRequestFormatter {
  public static func cURLCommand(from request: URLRequest) -> String {
    var command = "curl -X \(request.httpMethod ?? "")"
    if let body = request.httpBody,
      var HTTPBodyString = String(bytes: body, encoding: .utf8) {
      HTTPBodyString = HTTPBodyString.replacingOccurrences(of: "\\", with: "\\\\")
      HTTPBodyString = HTTPBodyString.replacingOccurrences(of: "`", with: "\\`")
      HTTPBodyString = HTTPBodyString.replacingOccurrences(of: "\"", with: "\\\"")
      HTTPBodyString = HTTPBodyString.replacingOccurrences(of: "$", with: "\\$")
      command ++= "-d \"\(HTTPBodyString)\""
    }
    if let header = request.allHTTPHeaderFields?["Accept-Encoding"],
    header.contains("gzip") {
      command ++= "--compressed"
    }
    if let url = request.url,
      let cookies = HTTPCookieStorage.shared.cookies(for: url),
      cookies.count > 0 {
      let cookieString = cookies.compactMap { "\($0.name)=\($0.value);" }.joined()
      command ++= "--cookie \"\(cookieString)\""
    }
    request.allHTTPHeaderFields?.forEach {
      command ++= "-H \("'\($0.key): \($0.value.replacingOccurrences(of: "\'", with: "\\\'"))'")"
    }
    command ++= "\"\(request.url?.absoluteString ?? "")\""

    return command
  }
}
