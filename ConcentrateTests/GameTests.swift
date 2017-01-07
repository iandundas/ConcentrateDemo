//
//  ConcentrateTests.swift
//  ConcentrateTests
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import XCTest
import Nimble
import ReactiveKit
@testable import Concentrate

class GameTests: XCTestCase {
    
    let twoPlayers = [
        FakePlayer(name: "Player 1"),
        FakePlayer(name: "Player 2")]
    
    let fakePictures = [
        FakePicture(name: "Cat 1"),
        FakePicture(name: "Cat 2"),
        FakePicture(name: "Cat 3"),
    ]
    
    let bag = DisposeBag()
    
    var moves: SafePublishSubject<Move>!
    var regularGame: Signal<GameState<FakePlayer>, String>!
    
    
    override func setUp() {
        super.setUp()
        moves = SafePublishSubject<Move>()
        regularGame = game(players: twoPlayers, pictures: fakePictures, moves: moves)
    }
    
    override func tearDown() {
        moves = nil
        regularGame = nil
        
        bag.dispose()
        super.tearDown()
    }
    
    // MARK: Inits
    
    func testGameRejectsEmptyArrayOfPictures(){
        let theGame = game(players: twoPlayers, pictures: [FakePicture](), moves: moves)
        expect(theGame).to(beNil())
    }
    
    func testGameRejectsEmptyArrayOfPlayers(){
        let theGame = game(players: [FakePlayer](), pictures: [FakePicture](), moves: moves)
        expect(theGame).to(beNil())
    }

    func testGameInitsWithPicturesAndPlayers(){
        let theGame = game(players: twoPlayers, pictures: fakePictures, moves: moves)
        expect(theGame).toNot(beNil())
    }
    
    
    // MARK: Generates board
    func testGameStartsWithValidPlayer(){
        
        let firstMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).bind(to: firstMove).dispose(in: bag)
        
        expect(firstMove.value?.player).to(equal(twoPlayers[0]))
        
    }
    
    func testGameGivesValidInitialBoardWithTwoOfEachPicture(){
        
        let firstMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).bind(to: firstMove).dispose(in: bag)
        
        // Tiles should be number of pictures * 2
        let tiles = firstMove.value!.board.tiles
        expect(tiles).to(haveCount(fakePictures.count * 2))
        
        // Strip first picture and check:
        let tilesMinusPicture0 = tiles.filter  { (tile) -> Bool in
            guard case .filled(let picture as FakePicture) = tile else {fatalError("Wasn't expecting blank tiles")}
            return picture != self.fakePictures[0]
        }
        expect(tilesMinusPicture0).to(haveCount((fakePictures.count * 2) - 2))
        
        
        // Then strip second picture and check:
        let tilesMinusPicture1 = tilesMinusPicture0.filter  { (tile) -> Bool in
            guard case .filled(let picture as FakePicture) = tile else {fatalError("Wasn't expecting blank tiles")}
            return picture != self.fakePictures[1]
        }
        expect(tilesMinusPicture1).to(haveCount((fakePictures.count * 2) - 4))
        
        
        // Then strip last picture and check:
        let tilesMinusPicture2 = tilesMinusPicture1.filter  { (tile) -> Bool in
            guard case .filled(let picture as FakePicture) = tile else {fatalError("Wasn't expecting blank tiles")}
            return picture != self.fakePictures[2]
        }
        expect(tilesMinusPicture2).to(beEmpty())
    }
    
    
    // MARK: Moves! 
    
    func testFailingFirstMoveAdvancesGameStateToNextPlayer(){
        
        let secondMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondMove).dispose(in: bag)
        
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.failure)
        
        expect(secondMove.value?.player).to(equal(twoPlayers[1]))
    }
    
    func testSuccessfulFirstMoveAdvancesGameStateForSamePlayer(){
        
        let secondMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondMove).dispose(in: bag)
        
        // First player takes a turn (they succeed), then it's their turn again
        let completedTile = Tile.filled(picture: fakePictures[0])
        moves.next(Move.success(tile: completedTile))
        
        expect(secondMove.value?.player).to(equal(twoPlayers[0]))
    }

}

