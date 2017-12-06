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
        "first_name": "Vasya",
        "last_name": "Pupkin"
      ],
      "players": [
        [
          "first_name": "Vasya",
          "last_name": "Pupkin"
        ],
        [
          "first_name": "Petya",
          "last_name": "Ronaldo"
        ]
      ],
      "players?": [
        [
          "first_name": "Vasya",
          "last_name": "Pupkin"
        ],
        [
          "first_name": "Petya",
          "last_name": "Ronaldo"
        ],
        [
          "first_name": "Kek",
          "lastname": "NoKek"
        ]
      ],
      "team": [
        "name": "France",
        "players": [
          [
            "first_name": "Vasya",
            "last_name": "Pupkin"
          ],
          [
            "first_name": "Petya",
            "last_name": "Ronaldo"
          ]
        ]
      ],
      "teams": [
        [
          "name": "France",
          "players": [
            [
              "first_name": "Vasya",
              "last_name": "Pupkin"
            ],
            [
              "first_name": "Petya",
              "last_name": "Ronaldo"
            ]
          ]
        ]
      ],
      "match": [
        "homeTeam": [
          "name": "France",
          "players": []
        ],
        "awayTeam": [
          "name": "Belarus",
          "players": [ ]
        ],
        "date": 1507654800
      ]
    ]
  ]

  func testTeam() {
    do {
      let request = try RequestBuilder<SingleResult<TeamModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/team").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let team = result.model

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
      let request = try RequestBuilder<SingleResult<PlayerModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/player").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let player = result.model
      expect(player.firstName) == "Vasya"
      expect(player.lastName) == "Pupkin"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testPlayers() {
    do {
      let request = try RequestBuilder<MultipleResults<PlayerModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/players").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let players = result.models
      expect(players[0].firstName) == "Vasya"
      expect(players[0].lastName) == "Pupkin"

      expect(players[1].firstName) == "Petya"
      expect(players[1].lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

//  func testOptionalPlayers() {
//    do {
//      let request = try RequestBuilder<MultipleResults<PlayerModel>>()
//        .setURLString("\(Params.API.baseURL)/post").setMethod(.POST).setParams(.json(data))
//        .setXPath("json/data/players?").build()
//
//      let response = try Gnomon.models(for: request).toBlocking().first()
//
//      expect(response).notTo(beNil())
//
//      guard let result = response?.result else {
//        throw "can't extract response"
//      }
//
//      let players = result.models
//      expect(players.count) == 3
//
//      expect(players[0].firstName) == "Vasya"
//      expect(players[0].lastName) == "Pupkin"
//
//      expect(players[1].firstName) == "Petya"
//      expect(players[1].lastName) == "Ronaldo"
//
//      expect(players[2]).to(beNil())
//    } catch {
//      fail("\(error)")
//      return
//    }
//  }

  func testXPathWithArrayIndex() {
    do {
      let request = try RequestBuilder<SingleResult<PlayerModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/players[0]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      let player = result.model
      expect(player.firstName) == "Vasya"
      expect(player.lastName) == "Pupkin"
    } catch {
      fail("\(error)")
      return
    }

    do {
      let request = try RequestBuilder<SingleResult<PlayerModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/teams[0]/players[1]").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        fail("can't extract response")
        return
      }

      let player = result.model
      expect(player.firstName) == "Petya"
      expect(player.lastName) == "Ronaldo"
    } catch {
      fail("\(error)")
      return
    }
  }

  func testMatchWithCustomizedDecoder() {
    do {
      let request = try RequestBuilder<SingleResult<MatchModel>>().setURLString("\(Params.API.baseURL)/post")
        .setMethod(.POST).setParams(.json(data)).setXPath("json/data/match").build()

      let response = try Gnomon.models(for: request).toBlocking().first()

      expect(response).notTo(beNil())

      guard let result = response?.result else {
        throw "can't extract response"
      }

      let match = result.model
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

}
