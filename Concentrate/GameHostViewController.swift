//
//  GameHostViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond



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
        
        title = "Concentrate"
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
