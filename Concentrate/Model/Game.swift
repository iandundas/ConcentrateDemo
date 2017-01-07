//
//  Game.swift
//  Concentrate
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import GameplayKit

extension String: Error{}

func game<Player: PlayerType, Picture: PictureType>(players: [Player], pictures: [Picture], moves: SafePublishSubject<Move<Picture>>) -> Signal<GameState<Player>, String>? {
    guard players.count > 0 && pictures.count > 0 else {return nil}
    
    let playerIterator = players.turnIterator()
    
    let signal = Signal<GameState<Player>, String> { observer in
        let bag = DisposeBag()
        var previousBoard: Board? = nil
        var currentPlayer: Player = playerIterator.next()!
        
        // initial state:
        let initialBoardConfiguration = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: pictures + pictures) as! [Picture]
        let initialTiles: [Tile] = initialBoardConfiguration.map { .filled(picture: $0) }
        let initialBoard = Board(tiles: initialTiles)
        previousBoard = initialBoard
        observer.next(.readyForTurn(board: initialBoard, player: currentPlayer))
        
        moves.observeNext(with: { (move) in
            // in the scope of a move, the previousBoard is really the current operative board, so "currentBoard".
            guard let currentBoard = previousBoard else { observer.failed("Logical error: no previous board configuration found"); return}
            
            switch move {
            // If move was successful,
            // - player gets a point
            // - player gets another go
            case .success(picture: let picture):
                // ensure the picture is still present on the board
                guard currentBoard.tiles.flatMap(toPicture).contains(where: {$0.id == picture.id}) else {
                    observer.failed("Logical error: given picture is missing or already completed"); return
                }
                let tiles = currentBoard.tiles.map(matchingTilesAsBlanks(pictureID: picture.id))
                let nextBoard = Board(tiles: tiles)
                previousBoard = nextBoard
                observer.next(.readyForTurn(board: nextBoard, player: currentPlayer))
                
            // If move was unsuccessful,
            // - turn moves to the next player
            case .failure:
                guard let nextPlayer = playerIterator.next() else { fatalError("Fatal Error: could not retrieve the next player"); }
                currentPlayer = nextPlayer
                observer.next(.readyForTurn(board: currentBoard, player: nextPlayer))
            }
        }).dispose(in: bag)
        
        return bag
    }
    
    return signal
}

enum GameState<Player: PlayerType> {
    case readyForTurn(board: Board, player: Player)
    case ended
}



protocol PlayerType: Equatable {
    var name: String {get}
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

struct RealPlayer{
    let name: String
}

struct Board {
    let tiles: [Tile]
}

protocol PictureType{
    var id: String {get}
    func image(size: CGSize) -> Signal<UIImage, String>
}

enum Tile {
    case blank
    case filled(picture: PictureType)
}

enum Move<Picture: PictureType> {
    case success(picture: Picture)
    case failure
}

// Use currying to create a filter function:
func removeTilesWithPictureID(id: String) -> (Tile) -> Bool {
    return { tile in
        switch tile {
        case .blank: return true
        case let .filled(picture: picture): return picture.id != id
        }
    }
}

func toPicture(tile: Tile) -> PictureType? {
    guard case let Tile.filled(picture) = tile else {return nil}
    return picture
}

func matchingTilesAsBlanks(pictureID: String) -> (Tile) -> Tile {
    return { tile -> Tile in
        if case let Tile.filled(picture) = tile, picture.id == pictureID{
            return Tile.blank
        }
        return tile
    }
}
