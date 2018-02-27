//
//  DecodableSpec.swift
//  Gnomon
//
//  Created by Vladimir Burdukov on 26/9/17.
//

import XCTest
import Nimble
import Gnomon

struct PlayerModel: DecodableModel {

  let firstName: String
  let lastName: String

  enum CodingKeys: String, CodingKey {
    case firstName = "first_name"
    case lastName = "last_name"
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

  let data: [String: Any] = [
    "data": [
      "player": [
        "first_name": "Vasya", "last_name": "Pupkin"
      ],
      "players": [
        [
          "first_name": "Vasya", "last_name": "Pupkin"
        ],
        [
          "first_name": "Petya", "last_name": "Ronaldo"
        ]
      ],
      "players?": [
        [
          "first_name": "Vasya", "last_name": "Pupkin"
        ],
        [
          "first_name": "Petya", "last_name": "Ronaldo"
        ],
        [
          "first_name": "Kek", "lastname": "NoKek"
        ]
      ],
      "team": [
        "name": "France",
        "players": [
          [
            "first_name": "Vasya", "last_name": "Pupkin"
          ],
          [
            "first_name": "Petya", "last_name": "Ronaldo"
          ]
        ]
      ],
      "teams": [
        [
          "name": "France",
          "players": [
            [
              "first_name": "Vasya", "last_name": "Pupkin"
            ],
            [
              "first_name": "Petya", "last_name": "Ronaldo"
            ]
          ],
          "lineups": [
            [
              [
                "first_name": "Vasya", "last_name": "Pupkin"
              ],
              [
                "first_name": "Petya", "last_name": "Ronaldo"
              ]
            ]
          ]
        ]
      ],
      "match": [
        "homeTeam": [
          "name": "France", "players": []
        ],
        "awayTeam": [
          "name": "Belarus", "players": []
        ],
        "date": 1507654800
      ],
      "matches": [
        [
          "homeTeam": [
            "name": "France",
            "players": []
          ],
          "awayTeam": [
            "name": "Belarus",
            "players": []
          ],
          "date": 1507654800
        ]
      ]
    ]
  ]

  func testTeam() {
    do {
      let request = try RequestBuilder<TeamModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/team").build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      let team = response.result

      expect(team.name) == "France"
      expect(team.players[0].firstName) == "Vasya"
      expect(team.players[0].lastName) == "Pupkin"

      expect(team.players[1].firstName) == "Petya"
      expect(team.players[1].lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlayer() {
    do {
      let request = try RequestBuilder<PlayerModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/player").build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      let player = response.result
      expect(player.firstName) == "Vasya"
      expect(player.lastName) == "Pupkin"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlayers() {
    do {
      let request = try RequestBuilder<[PlayerModel]>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/players").build()
      guard let response = try Gnomon.models(for: request).toBlocking().first() else {

        return fail("can't extract response")
      }

      let players = response.result
      expect(players[0].firstName) == "Vasya"
      expect(players[0].lastName) == "Pupkin"

      expect(players[1].firstName) == "Petya"
      expect(players[1].lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testOptionalPlayers() {
    do {
      let request = try RequestBuilder<[PlayerModel?]>()
        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST).setParams(.json(data))
        .setXPath("json/data/players?").build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      let players = response.result
      expect(players.count) == 3

      expect(players[0]?.firstName) == "Vasya"
      expect(players[0]?.lastName) == "Pupkin"

      expect(players[1]?.firstName) == "Petya"
      expect(players[1]?.lastName) == "Ronaldo"

      expect(players[2]).to(beNil())
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMatchWithCustomizedDecoder() {
    do {
      let request = try RequestBuilder<MatchModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/match").build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      let match = response.result
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

    } catch {
      fail("\(error)")
      return
    }
  }

  func testMatchesWithCustomizedDecoder() {
    do {
      let request = try RequestBuilder<[MatchModel]>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/matches").build()

      guard let response = try Gnomon.models(for: request).toBlocking().first() else {
        return fail("can't extract response")
      }

      let match = response.result[0]
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
    } catch {
      fail("\(error)")
      return
    }
  }

  func testXPathWithArrayIndex() {
    do {
      let request = try RequestBuilder<PlayerModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/players[0]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let player = response?.result else {
        fail("can't extract response")
        return
      }

      expect(player.firstName) == "Vasya"
      expect(player.lastName) == "Pupkin"
    } catch {
      fail("\(error)")
      return
    }

    do {
      let request = try RequestBuilder<PlayerModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/players[1]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let player = response?.result else {
        fail("can't extract response")
        return
      }

      expect(player.firstName) == "Petya"
      expect(player.lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testXPathWithMultipleArrayIndices() {
    do {
      let request = try RequestBuilder<PlayerModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/lineups[0][0]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let player = response?.result else {
        fail("can't extract response")
        return
      }

      expect(player.firstName) == "Vasya"
      expect(player.lastName) == "Pupkin"
    } catch {
      fail("\(error)")
      return
    }

    do {
      let request = try RequestBuilder<PlayerModel>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/lineups[0][1]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let player = response?.result else {
        fail("can't extract response")
        return
      }

      expect(player.firstName) == "Petya"
      expect(player.lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

}
