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
        Player(name: "Player 1"),
        Player(name: "Player 2")]
    
    let fakePictures = [
        FakePicture(name: "Cat 1"),
        FakePicture(name: "Cat 2"),
        FakePicture(name: "Cat 3"),
        FakePicture(name: "Cat 4"),
        FakePicture(name: "Cat 5"),
    ]
    
    var movesSubject: SafePublishSubject<Move>!
    
    override func setUp() {
        super.setUp()
        movesSubject = SafePublishSubject<Move>()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    // MARK: Inits
    
    func testGameRejectsEmptyArrayOfPictures(){
        let theGame = game(players: twoPlayers, pictures: [Picture](), moves: movesSubject)
        expect(theGame).to(beNil())
    }
    
    func testGameRejectsEmptyArrayOfPlayers(){
        let theGame = game(players: [Player](), pictures: [Picture](), moves: movesSubject)
        expect(theGame).to(beNil())
    }

    func testGameInitsWithPicturesAndPlayers(){
        let theGame = game(players: [Player](), pictures: [Picture](), moves: movesSubject)
        expect(theGame).toNot(beNil())
    }
    
    
    // MARK: Generates board
    
//    func testGameGivesValidBoardWithTwoOfEachPicture(){
////        let game = Game(players: twoPlayers, pictures: fakePictures)
//    }
    
    
    
}
