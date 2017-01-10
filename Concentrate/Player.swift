//
//  Player.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation



protocol PlayerType: Equatable, Hashable {
    var name: String {get}
}

extension PlayerType{
    var hashValue: Int {
        return name.hashValue
    }
}

func ==<Player: PlayerType>(a: Player, b: Player) -> Bool {
    return a.name == b.name
}

extension Array where Element: PlayerType {
    func turnIterator()->AnyIterator<Element> {
        var i: Int = 0
        
        return AnyIterator {
            guard self.count > 0 else {return nil}
            
            if i >= self.count {
                i = 0
            }
            
            let returnable = self[i]
            i = i + 1
            return returnable
        }
    }
}

struct RealPlayer: PlayerType{
    let name: String
}
