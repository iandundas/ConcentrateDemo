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
        
        thisgame.observe { event in
            print("Game event: \(event)")
        }
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        let gameHost = GameHostViewController.create { (host) -> GameHostViewModel in
            return GameHostViewModel()
        }
        
        presenter.present(gameHost, animated: false) {
            self.thisgame.observe { [weak self] (event: Event<GameState<RealPlayer>, String>) in
                guard let strongSelf = self else {return}
                
                switch event {
                case .next(let gameState):
                    guard let board = gameState.board, let player = gameState.player else {break}
                    
                    let turnViewController = TurnViewController.create { (viewController) -> TurnViewModel<RealPlayer, DevPicture> in
                        let viewModel = TurnViewModel<RealPlayer, DevPicture>(
                            actions: viewController.actions, board: board, player: player, scoreboard: gameState.score)
                        
                        // pass user moves out to the Game
                        viewModel.resultOfUserTurn
                            .bind(to: strongSelf.moves)
                            .dispose(in: viewController.reactive.bag)
                        
                        return viewModel
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
                child.view.frame = view.frame.insetBy(dx: 20, dy: 20)
                child.didMove(toParentViewController: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
    }
}


class TurnViewModel<Player: PlayerType, Picture: PictureType> {
    private let board: Board
    private let player: Player
    private let scoreboard: Scoreboard<Player>
    
    let actions: TurnViewController.Actions
    
    let resultOfUserTurn = PublishSubject1<Move<Picture>>()
    
    private let bag = DisposeBag()
    
    init(actions: TurnViewController.Actions, board: Board, player: Player, scoreboard: Scoreboard<Player>){
        self.actions = actions
        self.board = board
        self.player = player
        self.scoreboard = scoreboard
        
        let firstTileChoice = actions.selectedCell.map { board.tiles[$0] }.filter(include: filled).element(at: 0)
        let secondTileChoice = actions.selectedCell.map { board.tiles[$0] }.filter(include: filled).element(at: 1)
        
        // Combine the signals from user's first and second choice,
        // and map to .success or .failure
        // then bind the result to the ViewModel output `resultOfUserTurn`:
        combineLatest(firstTileChoice, secondTileChoice)
            .mapTileCombinationToMoveResult()
            .bind(to: self.resultOfUserTurn)
        
        combineLatest(firstTileChoice, secondTileChoice).observeNext { (x) in
            print("Tapped: \(x)")
        }
        
        self.resultOfUserTurn.observeNext { (move) in
            print("result: \(move)")
        }
    }
    
    var cellCount: Int {
        let count = board.tiles.count
        return count
    }
    
    func backgroundColor(cellID: Int) -> UIColor{
        let tile = self.board.tiles[cellID]
        guard case let .filled(picture) = tile else {
            return .clear
        }
        
        switch picture.id {
            case "0": fallthrough
            case "9": return UIColor.black
                
            case "1": fallthrough
            case "10": return UIColor.blue
                
            case "2": fallthrough
            case "11": return UIColor.yellow
            
            case "3": fallthrough
            case "12": return UIColor.green
            
            case "4": fallthrough
            case "13": return UIColor.red

            case "5": fallthrough
            case "14": return UIColor.orange

            case "6": fallthrough
            case "15": return UIColor.gray

            case "7": fallthrough
            case "16": return UIColor.lightGray

            case "8": fallthrough
            case "17": return UIColor.cyan
            
            default: fatalError()
        }
    }
}


extension SignalProtocol where Element == (Tile, Tile), Error == NoError {
    func mapTileCombinationToMoveResult<Picture: PictureType>() -> SafeSignal<Move<Picture>>{
        return self
            .filter { (tileA, tileB) -> Bool in
                guard let pictureA = tileA.picture, let pictureB = tileB.picture else {return false}
                let result = pictureA.id == pictureB.id
                return result
            }.map { (tile,_) -> Picture? in
                return tile.picture as? Picture
            }
            .ignoreNil()
            .map { Move<Picture>.success(picture: $0) }
    }
}


class TurnViewController: BaseBoundViewController<TurnViewModel<RealPlayer, DevPicture>>, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public static func create(viewModelFactory: @escaping (TurnViewController) -> TurnViewModel<RealPlayer, DevPicture>) -> TurnViewController{
        return create(storyboard: UIStoryboard(name: "Turn", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! TurnViewController
    }
    
    @IBOutlet var collectionView: UICollectionView!{
        didSet{
//            collectionView?.delegate = self
            collectionView?.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.purple
        
    }
    
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return viewModel.cellCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DevCell", for: indexPath)
        cell.backgroundColor = viewModel.backgroundColor(cellID: indexPath.row)
        return cell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    // MARK: UICollectionViewDelegate
    
//    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
//        print("did select")
//    }

}


extension TurnViewController {
    struct Actions {
        public let selectedCell: SafeSignal<Int>
    }
    
    var actions: Actions {
        return Actions(
            selectedCell: collectionView.selectedCell
        )
    }
}

extension UICollectionView {
    var selectedCell: Signal<Int, NoError> {
        return reactive.delegate.signal(for: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:))) { (subject: PublishSubject<Int, NoError>, _: UICollectionView, indexPath: NSIndexPath) in
            subject.next(indexPath.row)
        }
    }
}
