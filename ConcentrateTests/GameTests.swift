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
    
    var movesSubject: SafePublishSubject<Move>!
    var regularGame: Signal<GameState<FakePlayer>, String>!
    
    
    override func setUp() {
        super.setUp()
        movesSubject = SafePublishSubject<Move>()
        regularGame = game(players: twoPlayers, pictures: fakePictures, moves: movesSubject)
    }
    
    override func tearDown() {
        movesSubject = nil
        regularGame = nil
        
        bag.dispose()
        super.tearDown()
    }
    
    // MARK: Inits
    
    func testGameRejectsEmptyArrayOfPictures(){
        let theGame = game(players: twoPlayers, pictures: [FakePicture](), moves: movesSubject)
        expect(theGame).to(beNil())
    }
    
    func testGameRejectsEmptyArrayOfPlayers(){
        let theGame = game(players: [FakePlayer](), pictures: [FakePicture](), moves: movesSubject)
        expect(theGame).to(beNil())
    }

    func testGameInitsWithPicturesAndPlayers(){
        let theGame = game(players: twoPlayers, pictures: fakePictures, moves: movesSubject)
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
    

}

