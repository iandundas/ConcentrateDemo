//
//  Tile.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit

enum Tile:Equatable {
    case blank
    case filled(picture: PictureType)
    
    var blank: Bool? {
        guard case .blank = self else {return false}
        return true
    }
    var picture: PictureType? {
        guard case let .filled(picture) = self else {return nil}
        return picture
    }
    
    static func ==(a: Tile, b: Tile) -> Bool {
        switch (a,b){
        case (.blank, .blank): return true
        case let (.filled(picA), .filled(picB)): return picA.id == picB.id
        default: return false
        }
    }
}

func matchingTiles(tileA: Tile, tileB: Tile) -> Bool {
    guard let pictureA = tileA.picture, let pictureB = tileB.picture else {return false}
    let result = pictureA.id == pictureB.id
    return result
}

extension SignalProtocol where Element == (Tile, Tile), Error == NoError {
    func mapTileCombinationToMoveResult<Picture: PictureType>() -> SafeSignal<Move<Picture>>{
        
        return map { (a: Tile, b:Tile) -> Move<Picture> in
            guard let picture = a.picture as? Picture, matchingTiles(tileA: a, tileB: b) else {
                return .failure
            }
            return .success(picture: picture)
        }
    }
}
