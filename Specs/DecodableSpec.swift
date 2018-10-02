//
//  DecodableSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 26/9/17.
//

import XCTest
import Nimble

@testable import Gnomon

struct PlayerModel: DecodableModel, Equatable {

  let firstName: String
  let lastName: String

  enum CodingKeys: String, CodingKey {
    case firstName = "first_name"
    case lastName = "last_name"
  }

  static func ==(lhs: PlayerModel, rhs: PlayerModel) -> Bool {
    return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
  }

}

struct TeamModel: DecodableModel {

  let name: String
  let players: [PlayerModel]

}

struct MatchModel: DecodableModel {

  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }()

  let homeTeam: TeamModel
  let awayTeam: TeamModel

  let date: Date

}

class DecodableSpec: XCTestCase {

  func testTeam() {
    do {
      let request = try Request<TeamModel>(URLString: "https://example.com/")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        "name": "France",
        "players": [
          [
            "first_name": "Vasya", "last_name": "Pupkin"
          ],
          [
            "first_name": "Petya", "last_name": "Ronaldo"
          ]
        ]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let team = responses[0].result
        expect(team.name) == "France"
        expect(team.players[0].firstName) == "Vasya"
        expect(team.players[0].lastName) == "Pupkin"

        expect(team.players[1].firstName) == "Petya"
        expect(team.players[1].lastName) == "Ronaldo"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlayers() {
    do {
      let request = try Request<[PlayerModel]>(URLString: "https://example.com")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        [
          "first_name": "Vasya", "last_name": "Pupkin"
        ],
        [
          "first_name": "Petya", "last_name": "Ronaldo"
        ]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let players = responses[0].result

        expect(players).to(haveCount(2))

        expect(players[0]) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
        expect(players[1]) == PlayerModel(firstName: "Petya", lastName: "Ronaldo")
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testOptionalPlayers() {
    do {
      let request = try Request<[PlayerModel?]>(URLString: "https://example.com")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        [
          "first_name": "Vasya", "last_name": "Pupkin"
        ],
        [
          "first_name": "", "lastname": ""
        ]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let players = responses[0].result

        expect(players).to(haveCount(2))

        expect(players[0]) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
        expect(players[1]).to(beNil())
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMatchWithCustomizedDecoder() {
    do {
      let request = try Request<MatchModel>(URLString: "https://example.com")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        "homeTeam": [
          "name": "France", "players": []
        ],
        "awayTeam": [
          "name": "Belarus", "players": []
        ],
        "date": 1507654800
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let match = responses[0].result

        expect(match.homeTeam.name) == "France"
        expect(match.awayTeam.name) == "Belarus"
        var components = DateComponents()

        components.year = 2017
        components.month = 10
        components.day = 10
        components.hour = 19
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Europe/Paris")
        expect(match.date) == Calendar.current.date(from: components)
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMatchesWithCustomizedDecoder() {
    do {
      let request = try Request<[MatchModel]>(URLString: "https://example.com")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        [
          "homeTeam": [
            "name": "France", "players": []
          ],
          "awayTeam": [
            "name": "Belarus", "players": []
          ],
          "date": 1507654800
        ]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))
        expect(responses[0].result).to(haveCount(1))

        let match = responses[0].result[0]

        expect(match.homeTeam.name) == "France"
        expect(match.awayTeam.name) == "Belarus"
        var components = DateComponents()

        components.year = 2017
        components.month = 10
        components.day = 10
        components.hour = 19
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Europe/Paris")
        expect(match.date) == Calendar.current.date(from: components)
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testXPath() {
    do {
      let request = try Request<PlayerModel>(URLString: "https://example.com/").setXPath("json/data")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: [
        "json": ["data": ["first_name": "Vasya", "last_name": "Pupkin"]]
      ], cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let player = responses[0].result
        expect(player.firstName) == "Vasya"
        expect(player.lastName) == "Pupkin"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testXPathWithArrayIndex() {
    let data = [
      "teams": [
        [
          "name": "France",
          "players": [
            ["first_name": "Vasya", "last_name": "Pupkin"], ["first_name": "Petya", "last_name": "Ronaldo"]
          ]
        ]
      ]
    ]

    do {
      let request = try Request<PlayerModel>(URLString: "https://example.com/")
        .setXPath("teams[0]/players[0]")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: data, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let player = responses[0].result
        expect(player.firstName) == "Vasya"
        expect(player.lastName) == "Pupkin"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }

    do {
      let request = try Request<PlayerModel>(URLString: "https://example.com/")
        .setXPath("teams[0]/players[1]")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: data, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))

        let player = responses[0].result
        expect(player.firstName) == "Petya"
        expect(player.lastName) == "Ronaldo"
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

  func testXPathWithMultipleArrayIndices() {
    let data = [
      "matches": [
        [
          "id": 1,
          "lineups": [
            [
              ["first_name": "Vasya", "last_name": "Pupkin"]
            ],
            [
              ["first_name": "Vanya", "last_name": "Messi"], ["first_name": "Artem", "last_name": "Dzyuba"],
            ]
          ]
        ]
      ]
    ]
    do {
      let request = try Request<PlayerModel>(URLString: "https://example.com/")
        .setXPath("matches[0]/lineups[0][0]")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: data, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))
        expect(responses[0].result) == PlayerModel(firstName: "Vasya", lastName: "Pupkin")
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }

    do {
      let request = try Request<PlayerModel>(URLString: "https://example.com/")
        .setXPath("matches[0]/lineups[1][1]")
      request.httpSessionDelegate = try TestSessionDelegate.jsonResponse(result: data, cached: false)

      let result = Gnomon.models(for: request).toBlocking(timeout: BlockingTimeout).materialize()

      switch result {
      case let .completed(responses):
        expect(responses).to(haveCount(1))
        expect(responses[0].result) == PlayerModel(firstName: "Artem", lastName: "Dzyuba")
      case let .failed(_, error):
        fail("\(error)")
      }
    } catch {
      fail("\(error)")
      return
    }
  }

}
