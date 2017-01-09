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
        var scoreboard = Scoreboard(players: players)
        var currentPlayer: Player = playerIterator.next()!
        
        
        // initial state:
        let initialBoardConfiguration = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: pictures + pictures) as! [Picture]
        let initialTiles: [Tile] = initialBoardConfiguration.map { .filled(picture: $0) }
        let initialBoard = Board(tiles: initialTiles)
        previousBoard = initialBoard
        observer.next(.readyForTurn(board: initialBoard, player: currentPlayer, scoreboard: scoreboard))
        
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
                
                scoreboard.up(player: currentPlayer)
                
                let nextTiles = currentBoard.tiles.map(matchingTilesAsBlanks(pictureID: picture.id))
                let nextBoard = Board(tiles: nextTiles)
                
                if nextBoard.tiles.filter(filled).count > 0 {
                    previousBoard = nextBoard
                    observer.next(.readyForTurn(board: nextBoard, player: currentPlayer, scoreboard: scoreboard))
                }
                else{
                    observer.completed(with: .ended(scoreboard: scoreboard))
                }
                
            // If move was unsuccessful,
            // - turn moves to the next player
            case .failure:
                guard let nextPlayer = playerIterator.next() else { fatalError("Fatal Error: could not retrieve the next player"); }
                currentPlayer = nextPlayer
                observer.next(.readyForTurn(board: currentBoard, player: nextPlayer, scoreboard: scoreboard))
            }
        }).dispose(in: bag)
        
        return bag
    }
    
    return signal
}

enum GameState<Player: PlayerType> {
    case readyForTurn(board: Board, player: Player, scoreboard: Scoreboard<Player>)
    case ended(scoreboard: Scoreboard<Player>)
}

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

struct Board {
    let tiles: [Tile]
}

protocol PictureType{
    var id: String {get}
    func image(size: CGSize) -> Signal<UIImage, String>
}

struct DevPicture: PictureType {
    let id: String
    
    func image(size: CGSize) -> Signal<UIImage, String> {
        return Signal.just(UIImage())
    }
}

enum Tile {
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
}


enum Move<Picture: PictureType> {
    case success(picture: Picture)
    case failure
}

// MARK: Mapping and Filtering:

// Use currying to create a filter function:
func removeTilesWithPictureID(id: String) -> (Tile) -> Bool {
    return { tile in
        switch tile {
        case .blank: return true
        case let .filled(picture: picture): return picture.id != id
        }
    }
}

func filled(tile: Tile) -> Bool {
    if case Tile.filled(_) = tile {return true}
    return false
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

// MARK: Utility accessors:
extension GameState {
    var board: Board? {
        if case .readyForTurn(let board, _, _) = self { return board }
        return nil
    }
    var player: Player? {
        if case .readyForTurn(_, let player, _) = self { return player }
        return nil
    }
    var score: Scoreboard<Player> {
        switch self{
        case .readyForTurn(_, _, let scoreboard) : return scoreboard
        case .ended(let scoreboard): return scoreboard
        }
    }
    var ended: Bool{
        if case .ended = self { return true }
        return false
    }
}
