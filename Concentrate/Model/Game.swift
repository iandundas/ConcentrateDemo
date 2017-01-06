//
//  Game.swift
//  Concentrate
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

extension String: Error{}

func game(players: [Player], pictures: [Picture], moves: SafePublishSubject<Move>) -> Signal<(Board, Player), String>? {
    guard players.count > 0 && pictures.count > 0 else {return nil}
    let signal = Signal<(Board, Player), String> { observer in
        let bag = DisposeBag()
        
        return bag
    }
    
    return signal
}


struct Player{
    let name: String
}

struct Board {
    let tiles: [Tile]
}

protocol Picture{
    func image(size: CGSize) -> Signal<UIImage, String>
}


enum Tile {
    case blank
    case filled(picture: Picture)
}

enum Move {
    case success(tile: Tile)
    case failure
}
