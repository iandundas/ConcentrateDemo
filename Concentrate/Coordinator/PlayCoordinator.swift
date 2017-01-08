//
//  GameCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 07/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

class PlayCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "PlayCoordinator"
    let presenter: UIViewController
    var childCoordinators: [String : Coordinator] = [:]
    
    let moves = PublishSubject<Move<DevPicture>, NoError>()
    let thisgame: Signal<GameState<RealPlayer>, String>
    
    private let bag = DisposeBag()
    init(presenter: UIViewController){
        self.presenter = presenter

        let players = [
            RealPlayer(name: "Player 1"),
            RealPlayer(name: "Player 2")
        ]
        let pictures = [
            DevPicture(id: "0"), DevPicture(id: "1"), DevPicture(id: "2"),
            DevPicture(id: "3"), DevPicture(id: "4"), DevPicture(id: "5"),
            DevPicture(id: "6"), DevPicture(id: "7"), DevPicture(id: "8"),
        ]
        
        thisgame = game(players: players, pictures: pictures, moves: moves)!.shareReplay()
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        let gameHost = GameHostViewController.create { (host) -> GameHostViewModel in
            return GameHostViewModel()
        }
        
        presenter.present(gameHost, animated: false) {
            self.thisgame.observe { (event: Event<GameState<RealPlayer>, String>) in
                switch event {
                case .next(let gameState):
                    guard let board = gameState.board, let player = gameState.player else {break}
                    
                    let turnViewController = TurnViewController.create { (viewController) -> TurnViewModel in
                        return TurnViewModel(board: board, player: player, scoreboard: gameState.score)
                    }
                    
                    gameHost.turnViewController = turnViewController
                    
                case .failed(let error):
                    print("error: \(error)")
                    
                case .completed:
                    break;
                }
            }.dispose(in: self.bag)
            
            // Ready:
            completion?(self)
        }
        
        
        
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
}


class GameHostViewModel{}

class GameHostViewController: BaseBoundViewController<GameHostViewModel> {
    
    public static func create(viewModelFactory: @escaping (GameHostViewController) -> GameHostViewModel) -> GameHostViewController{
        return create(storyboard: UIStoryboard(name: "GameHost", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! GameHostViewController
    }

    var turnViewController: TurnViewController? = nil{
        didSet{
            // remove any existing old one:
            if let oldVC = oldValue{
                oldVC.willMove(toParentViewController: nil)
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParentViewController()
            }
            // add new one:
            if let child = turnViewController{
                addChildViewController(child)
                view.addSubview(child.view)
                view.frame = view.frame.insetBy(dx: 20, dy: 20)
                child.didMove(toParentViewController: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
    }
}


class TurnViewModel {
    init<Player: PlayerType>(board: Board, player: Player, scoreboard: Scoreboard<Player>){
        
    }
}

class TurnViewController: BaseBoundViewController<TurnViewModel> {
    
    //    let collectionView: UICollectionView
    
    public static func create(viewModelFactory: @escaping (TurnViewController) -> TurnViewModel) -> TurnViewController{
        return create(storyboard: UIStoryboard(name: "Turn", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! TurnViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.purple
        
    }
}
