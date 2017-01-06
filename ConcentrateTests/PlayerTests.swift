//
//  PlayerTests.swift
//  Concentrate
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import XCTest
import Nimble
import ReactiveKit
@testable import Concentrate

class PlayerTests: XCTestCase {
    
    let twoPlayers = [
        FakePlayer(name: "Player 1"),
        FakePlayer(name: "Player 2")]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: Test Iterator:
    func testIteratorLoopsBack(){
        let iterator = twoPlayers.turnIterator()
        
        expect(iterator.next()).to(equal(twoPlayers[0]))
        expect(iterator.next()).to(equal(twoPlayers[1]))
        expect(iterator.next()).to(equal(twoPlayers[0]))
    }
    
    func testIteratorHandlesSingleElement(){
        let iterator = [twoPlayers[0]].turnIterator()
        
        expect(iterator.next()).to(equal(twoPlayers[0]))
        expect(iterator.next()).to(equal(twoPlayers[0]))
    }
    
    func testIteratorHandlesEmpty(){
        let iterator = [FakePlayer]().turnIterator()
        
        expect(iterator.next()).to(beNil())
    }
}


