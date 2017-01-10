//
//  Scoreboard.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation

struct Scoreboard<Player: PlayerType>{
    var scores: [Player : Int]
    
    init(players: [Player]){
        scores = players.reduce([Player : Int]()) { (existing, player) -> [Player : Int] in
            var mut = existing
            mut.updateValue(0, forKey: player)
            return mut
        }
    }
    mutating func up(player: Player){
        guard let existingScore = scores[player] else {return}
        scores[player] = existingScore + 1
    }
    mutating func down(player: Player){
        guard let existingScore = scores[player], existingScore > 0 else {return}
        scores[player] = existingScore - 1
    }
}
