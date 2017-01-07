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
    
    var moves: SafePublishSubject<Move<FakePicture>>!
    var regularGame: Signal<GameState<FakePlayer>, String>!
    
    
    override func setUp() {
        super.setUp()
        moves = SafePublishSubject<Move<FakePicture>>()
        regularGame = game(players: twoPlayers, pictures: fakePictures, moves: moves)!.shareReplay()
        
        // Start the game!
        regularGame.observeCompleted {
            print("The game ended")
        }.dispose(in: bag)
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
        
        let firstState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).bind(to: firstState).dispose(in: bag)
        
        expect(firstState.value?.player).to(equal(twoPlayers[0]))
    }
    
    func testGameGivesValidInitialBoardWithTwoOfEachPicture(){
        
        let firstState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).bind(to: firstState).dispose(in: bag)
        
        // Tiles should be number of pictures * 2
        let tiles = firstState.value!.board!.tiles
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
        
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.failure)
        
        expect(secondState.value?.player).to(equal(twoPlayers[1]))
    }
    
    func testSuccessfulFirstMoveAdvancesGameStateForSamePlayer(){
        
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        // First player takes a turn (they succeed), then it's their turn again
        moves.next(Move.success(picture: fakePictures[0]))
        
        expect(secondState.value?.player).to(equal(twoPlayers[0]))
    }
    
    func testFailingFirstMoveFollowedBySuccessfulMoveIdentifiesCorrectNextPlayer(){
        
        let firstState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 0).bind(to: firstState).dispose(in: bag)
        
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        let thirdState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 2).bind(to: thirdState).dispose(in: bag)

        expect(firstState.value?.player).to(equal(twoPlayers[0]))

        print("making first move:")
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.failure)
        
        expect(secondState.value?.player).to(equal(twoPlayers[1]))
        
        print("making second move:")
        // Successful move by player 2:
        moves.next(Move.success(picture: fakePictures[0]))
        
        // Should still be player 2
        expect(thirdState.value?.player).to(equal(twoPlayers[1]))
    }
    
    func testSuccessfulFirstMoveAdvancesGameStateToABoardWithThatTileRemoved(){
        // Verify Second State (after 1 move)
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        moves.next(Move.success( picture: fakePictures[0]))
        
        // Should keep the same amount of tiles (filled or blank)
        expect(secondState.value?.board?.tiles).to(haveCount(fakePictures.count * 2))
        // Should now be one blank tile:
        expect(secondState.value?.board?.tiles.filter(onlyBlankTiles)).to(haveCount(2))
        
        // The remaining filled tiles should not contain the move we made before
        let remainingTilePictures: [FakePicture]? = secondState.value?.board?.tiles.filter(onlyFilledTiles).flatMap(toFakePicture)
        expect(remainingTilePictures).toNot(contain(fakePictures[0]))
    }
    
    func testMatchingAllTilesEndsTheGame(){
        moves.next(Move.success( picture: fakePictures[0]))
        moves.next(Move.success( picture: fakePictures[1]))
        moves.next(Move.success( picture: fakePictures[2]))
        
        let lastMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 3).bind(to: lastMove).dispose(in: bag)
        
        let neverMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 4).bind(to: neverMove).dispose(in: bag)
        
        expect(lastMove.value?.ended).to(beTrue())
        expect(neverMove.value?.ended).to(beNil()) // shouldn't be anything else
    }
    
    
    func testMatchingAllTilesWithMistakesEndsTheGame(){
        moves.next(Move.success( picture: fakePictures[0]))
        moves.next(Move.failure)
        moves.next(Move.success( picture: fakePictures[1]))
        moves.next(Move.failure)
        moves.next(Move.failure)
        moves.next(Move.failure)
        moves.next(Move.failure)
        moves.next(Move.success( picture: fakePictures[2]))
        
        let lastMove = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 8).bind(to: lastMove).dispose(in: bag)
        
        expect(lastMove.value?.ended).to(beTrue())
    }
    
    // MARK: Scores! 
    
    func testGameStartsWithValidScore(){
        
        let firstState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).bind(to: firstState).dispose(in: bag)
        
        let expected: [FakePlayer : Int] = [
            twoPlayers[0]: 0,
            twoPlayers[1]: 0,
        ]
        
        expect(firstState.value?.score.scores).to(equal(expected))
    }
    
    func testFailingFirstMoveScoreRemainsZeroZero(){
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.failure)
        
        let expected: [FakePlayer : Int] = [
            twoPlayers[0]: 0,
            twoPlayers[1]: 0,
            ]
        
        expect(secondState.value?.score.scores).to(equal(expected))
    }
    
    func testFirstMoveSuccessScore(){
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.success(picture: fakePictures[0]))
        
        let expected: [FakePlayer : Int] = [
            twoPlayers[0]: 1,
            twoPlayers[1]: 0,
            ]
        
        expect(secondState.value?.score.scores).to(equal(expected))
    }
    
    
    func testFailFirstMoveThenSucceedSecondMoveScore(){
        let secondState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 1).bind(to: secondState).dispose(in: bag)
        
        let thirdState = Property<GameState<FakePlayer>?>(nil)
        regularGame.suppressError(logging: true).element(at: 2).bind(to: thirdState).dispose(in: bag)
        
        // First player takes a turn (they fail), then it's player twos' turn
        moves.next(Move.failure)
        moves.next(Move.success(picture: fakePictures[0]))
        
        let expected: [FakePlayer : Int] = [
            twoPlayers[0]: 0,
            twoPlayers[1]: 1,
            ]
        
        expect(thirdState.value?.score.scores).to(equal(expected))
    }
}

// MARK: Mapping and Filtering: 

func onlyFilledTiles(tile: Tile) -> Bool {
    if case .filled(_) = tile {return true}
    return false
}

func onlyBlankTiles(tile: Tile) -> Bool {
    if case .blank = tile {return true}
    return false
}

func toFakePicture(tile: Tile) -> FakePicture? {
    if case let .filled(picture as FakePicture) = tile {return picture}
    return nil
}

//func ==<Player: PlayerType>(a: Dictionary<Player, Int>, b:Dictionary<Player, Int>) -> Bool {
//    return a == b
//}

