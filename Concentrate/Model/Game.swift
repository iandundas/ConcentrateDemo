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

func game<Player: PlayerType, Picture: PictureType>(players: [Player], pictures: [Picture], moves: SafePublishSubject<Move>) -> Signal<GameState<Player>, String>? {
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
        observer.next(GameState(board: initialBoard, player: playerIterator.next()!))
        
        moves.observeNext(with: { (move) in
            guard let previousBoard = previousBoard else { observer.failed("Logical error: no previous board configuration found"); return}
            guard let nextPlayer = playerIterator.next() else { fatalError("Fatal Error: could not retrieve the next player"); return}
            
            switch move {
            case .success(tile: let tile):
                fatalError()
                
            // If move was unsuccessful,
            // - turn moves to the next player
            case .failure:
                guard let nextPlayer = playerIterator.next() else { fatalError("Fatal Error: could not retrieve the next player"); return}
                let nextState = GameState<Player>(board: currentBoard, player: nextPlayer)
                observer.next(nextState)
            }
        }).dispose(in: bag)
        
        return bag
    }
    
    return signal
}

struct GameState<Player: PlayerType> {
    let board: Board
    let player: Player
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
    func image(size: CGSize) -> Signal<UIImage, String>
}


enum Tile {
    case blank
    case filled(picture: PictureType)
}

enum Move {
    case success(tile: Tile)
    case failure
}
