//
//  GameCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 07/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond
import SpriteKit
import RealmSwift

class PlayCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "PlayCoordinator"
    let presenter: UINavigationController
    var childCoordinators: [String : Coordinator] = [:]
    
    let shouldDismissCoordinator = SafePublishSubject<Void>()
    
    let moves = PublishSubject<Move<DevPicture>, NoError>()
    let thisgame: Signal<GameState<RealPlayer>, String>
    
    // convenience state: 
    let currentPlayer = ReactiveKit.Property<RealPlayer?>(nil)
    
    private let bag = DisposeBag()
    
    init(presenter: UINavigationController, players: [RealPlayer], pictures: [DevPicture]){
        self.presenter = presenter

        thisgame = game(players: players, pictures: pictures, moves: moves)!.shareReplay()
        
        thisgame
            .map { (gameState) -> RealPlayer? in
                guard case let .readyForTurn(_, player, _) = gameState else {return nil}
                return player
            }.suppressError(logging: false)
            .ignoreNil()
            .bind(to: currentPlayer)
        
        
        thisgame.observe { event in
            print("⚡️ Game Event: \(event)")
        }.dispose(in: bag)
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        // Create a Signal of the current Player, and pass it to the GameHost:

        
        let gameHostViewController = GameHostViewController.create { (host) -> GameHostViewModel in
            return GameHostViewModel(currentPlayer: self.currentPlayer.ignoreNil())
        }
        
        // On "Next" game events:
        thisgame.observeNext { [weak self] (gameState: GameState<RealPlayer>) in
            guard let strongSelf = self else {return}
            guard let board = gameState.board, let player = gameState.player else {return}
            
            let turnViewController = TurnViewController.create { (viewController) -> TurnViewModel<RealPlayer, DevPicture> in
                let viewModel = TurnViewModel<RealPlayer, DevPicture>(
                    actions: viewController.actions, board: board, player: player, scoreboard: gameState.score)
                
                // pass user moves out to the Game
                viewModel.resultOfUserTurn
                    .bind(to: strongSelf.moves)
                    .dispose(in: viewController.reactive.bag)
                
                return viewModel
            }
            
            gameHostViewController.turnViewController = turnViewController
        }.dispose(in: self.bag)
        
        
        // The last state of the game (.ended), we want to save the scores from:
        thisgame.last().observeNext { [weak self] (lastGameState) in
            guard let strongSelf = self, let realm = try? Realm() else {return}
            guard case .ended(let scoreboard) = lastGameState else {return}
            
            let sortedScores = scoreboard.scores.sorted(by: { (a: (key: RealPlayer, value: Int), b:(key: RealPlayer, value: Int)) -> Bool in
                return a.value > b.value
            })
            guard let firstWinner = sortedScores.first else {return}
            
            // Was it a draw?
            if sortedScores.count > 1, sortedScores[1].value == firstWinner.value{
                let secondWinner = sortedScores[1]
                try! realm.write {
                    realm.add(Score(value: ["playerName": firstWinner.key.name, "score": firstWinner.value]))
                    realm.add(Score(value: ["playerName": secondWinner.key.name, "score": secondWinner.value]))
                }
                strongSelf.pushWinner(winners: [firstWinner.key, secondWinner.key])
            }
            else{
                try! realm.write {
                    realm.add(Score(value: ["playerName": firstWinner.key.name, "score": firstWinner.value]))
                }
                strongSelf.pushWinner(winners: [firstWinner.key])
            }
        }.dispose(in: self.bag)
        
    
        // Ready:
        presenter.viewControllers = [gameHostViewController]
        completion?(self)
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
    func pushWinner(winners: [RealPlayer]){
        let winnerViewController = WinnerViewController.create { (vc) -> WinnerViewModel<RealPlayer> in
            return WinnerViewModel<RealPlayer>(players: winners)
        }
        
        winnerViewController.actions.tappedToClose.bind(to: shouldDismissCoordinator)
        
        presenter.pushViewController(winnerViewController, animated: false)
    }
    
}

