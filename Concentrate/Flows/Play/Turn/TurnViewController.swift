//
//  TurnViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond


class TurnViewModel<Player: PlayerType, Picture: PictureType> {
    let RevealAnimationDuration: TimeInterval = 1.0
    
    let actions: TurnViewController.Actions
    
    let resultOfUserTurn = PublishSubject1<Move<Picture>>()
    
    // After two turns, no more tapping allowed
    let disableUserInteraction: SafeSignal<Void>
    
    let scores: SafeSignal<String>
    
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
        
        
        let scorePairs = scoreboard.scores.map { (player: (key: Player, value: Int)) -> String in
            return "\(player.key.name): \(player.value)"
        }
        
        let scoreString = (scorePairs as NSArray).componentsJoined(by: ", ")
        scores = Signal.just(scoreString)
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
    @IBOutlet var scores: UILabel!
    
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
        
        bind(viewModel.scores, to: scores.reactive.text)
    }
    
    // MARK: UICollectionViewDelegate:
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TileCell else {return}
        guard cell.revealed == false else {return}
        
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
            cell.revealed = false
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

