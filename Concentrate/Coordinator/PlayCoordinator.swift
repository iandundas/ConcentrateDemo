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

class PlayCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "PlayCoordinator"
    let presenter: UINavigationController
    var childCoordinators: [String : Coordinator] = [:]
    
    let moves = PublishSubject<Move<DevPicture>, NoError>()
    let thisgame: Signal<GameState<RealPlayer>, String>
    
    // convenience state: 
    let currentPlayer = Property<RealPlayer?>(nil)
    
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
        
        
        // When the game is completed:
        thisgame.observeCompleted { [weak self] in
            guard let strongSelf = self else {return}
            
            let particleTest = ParticleViewController.create { (vc) -> ParticleViewModel in
                return ParticleViewModel(playerName: strongSelf.currentPlayer.value?.name ?? "")
            }
            strongSelf.presenter.pushViewController(particleTest, animated: false)
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
    
}
class ParticleViewModel{
    let playerName: String
    
    init(playerName: String){
        self.playerName = playerName
    }
}

class ParticleViewController: BaseBoundViewController<ParticleViewModel> {
    public static func create(viewModelFactory: @escaping (ParticleViewController) -> ParticleViewModel) -> ParticleViewController{
        return create(storyboard: UIStoryboard(name: "Winner", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! ParticleViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBOutlet var playerName: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerName.text = viewModel.playerName
        
        let skView = SKView(frame: view.frame)
        skView.backgroundColor = .clear
        skView.isOpaque = false
        view.insertSubview(skView, belowSubview: playerName)
        
        let scene = SKScene(size: skView.frame.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        
        let path = Bundle.main.path(forResource: "Fireworks", ofType: "sks")
        let fireworksParticle = NSKeyedUnarchiver.unarchiveObject(withFile: path!) as! SKEmitterNode
        
        fireworksParticle.position = playerName.center
        
        scene.addChild(fireworksParticle)
        skView.presentScene(scene)
        
        skView.alpha = 0
        UIView.animate(withDuration: 2) {
            skView.alpha = 1
        }
    }
}

class GameHostViewModel{
    
    let playerName: SafeSignal<String>
    private let currentPlayer: Signal<RealPlayer, NoError>
    init(currentPlayer: Signal<RealPlayer, NoError>){
        self.currentPlayer = currentPlayer
        playerName = currentPlayer.map {"It is \($0.name)'s turn!!"}
    }
}



class GameHostViewController: BaseBoundViewController<GameHostViewModel> {
    
    public static func create(viewModelFactory: @escaping (GameHostViewController) -> GameHostViewModel) -> GameHostViewController{
        return create(storyboard: UIStoryboard(name: "GameHost", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! GameHostViewController
    }

    @IBOutlet var gameFrame: UIView!
    @IBOutlet var playerName: UILabel!
    
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
                child.view.frame = gameFrame.frame
                child.didMove(toParentViewController: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        turnViewController?.view.frame = gameFrame.frame
    }
    
    override func bindTo(viewModel: GameHostViewModel) {
        viewModel.playerName.observeNext { [weak self] (title) in
            guard let strongSelf = self else {return}
            strongSelf.playerName.text = title
        }.dispose(in: reactive.bag)
    }
}


class TurnViewModel<Player: PlayerType, Picture: PictureType> {
    let RevealAnimationDuration: TimeInterval = 1.0
    
    let actions: TurnViewController.Actions
    
    let resultOfUserTurn = PublishSubject1<Move<Picture>>()

    // After two turns, no more tapping allowed
    let disableUserInteraction: SafeSignal<Void>
    
    private let board: Board
    private let player: Player
    private let scoreboard: Scoreboard<Player>
    private let bag = DisposeBag()
    
    init(actions: TurnViewController.Actions, board: Board, player: Player, scoreboard: Scoreboard<Player>){
        self.actions = actions
        self.board = board
        self.player = player
        self.scoreboard = scoreboard
        
        let tileTaps = actions.selectedCell
            .map { (index: $0, tile: board.tiles[$0]) } // combine index with Tile
            .filter {filled(tile: $0.tile)} // filter out .blank Tiles
            .distinct { $0.index != $1.index } // ignore tap if it was on the same Tile index
            .map {$0.tile} // only need the tile now
        
        let firstTile = tileTaps.element(at: 0)
        let secondTile = tileTaps.element(at: 1)
        
        disableUserInteraction = combineLatest(firstTile, secondTile).map {_,_ in ()}
        
        // Combine the signals from user's first and second choice,
        // and map to .success or .failure
        // then bind the result to the ViewModel output `resultOfUserTurn`:
        combineLatest(firstTile, secondTile)
            .mapTileCombinationToMoveResult()
            .delay(interval: RevealAnimationDuration, on: DispatchQueue.main)
            .bind(to: self.resultOfUserTurn)
    }
    
    var cellCount: Int {
        let count = board.tiles.count
        return count
    }
    
    func image(cellID:Int) -> UIImage? {
        let tile = self.board.tiles[cellID]
        guard case let .filled(picture) = tile else { return nil }
        
        return picture.loadedImage
    }
}


func matchingTiles(tileA: Tile, tileB: Tile) -> Bool {
    guard let pictureA = tileA.picture, let pictureB = tileB.picture else {return false}
    let result = pictureA.id == pictureB.id
    return result
}


extension SignalProtocol where Element == (Tile, Tile), Error == NoError {
    func mapTileCombinationToMoveResult<Picture: PictureType>() -> SafeSignal<Move<Picture>>{
        
        return map { (a: Tile, b:Tile) -> Move<Picture> in
            guard let picture = a.picture as? Picture, matchingTiles(tileA: a, tileB: b) else {
                return .failure
            }
            return .success(picture: picture)
        }
    }
}


class TurnViewController: BaseBoundViewController<TurnViewModel<RealPlayer, DevPicture>>, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public static func create(viewModelFactory: @escaping (TurnViewController) -> TurnViewModel<RealPlayer, DevPicture>) -> TurnViewController{
        return create(storyboard: UIStoryboard(name: "Turn", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! TurnViewController
    }
    
    @IBOutlet var collectionView: UICollectionView!{
        didSet{
            collectionView?.dataSource = self
            collectionView?.reactive.delegate.forwardTo = self
        }
    }
    
    var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        //
        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: more sophisticated way of calculating cell size:
        if viewModel.cellCount == DifficultyLevel.easy.rawValue * 2{
            if UIDevice.current.userInterfaceIdiom == .pad{
                layout.itemSize = CGSize(width: 160, height: 160)
            }
            else{
                layout.itemSize = CGSize(width: 80, height: 80)
            }
        }
        else{
            if UIDevice.current.userInterfaceIdiom == .pad{
                layout.itemSize = CGSize(width: 120, height: 120)
            }
            else{
                layout.itemSize = CGSize(width: 60, height: 60)
            }
        }
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        collectionView?.collectionViewLayout = layout
    }
    
    override func bindTo(viewModel: TurnViewModel<RealPlayer, DevPicture>) {
        viewModel.disableUserInteraction.observeNext { [weak self] in
            self?.collectionView.isUserInteractionEnabled = false
        }.dispose(in: reactive.bag)
    }
    
    // MARK: UICollectionViewDelegate:
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TileCell else {return}
        
        UIView.animate(withDuration: viewModel.RevealAnimationDuration / 2) {
            cell.transform = cell.transform.scaledBy(x: 1.2, y: 1.2)
            cell.revealed = true
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return viewModel.cellCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath) as! TileCell
        
        if let picture = viewModel.image(cellID: indexPath.row){
            cell.pictureImageView.image = picture
        }
        else{
            cell.isHidden = true
        }
        return cell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
}


extension TurnViewController {
    struct Actions {
        public let selectedCell: SafeSignal<Int>
    }
    
    var actions: Actions {
        return Actions(
            selectedCell: collectionView.reactive.selectedCell
        )
    }
}


