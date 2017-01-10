//
//  WinnerViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond
import SpriteKit

class WinnerViewModel{
    let playerName: String
    
    init(playerName: String){
        self.playerName = playerName
    }
}

class WinnerViewController: BaseBoundViewController<WinnerViewModel> {
    public static func create(viewModelFactory: @escaping (WinnerViewController) -> WinnerViewModel) -> WinnerViewController{
        return create(storyboard: UIStoryboard(name: "Winner", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! WinnerViewController
    }
    
    @IBOutlet var playerName: UILabel!
    
    let tappedToClose = SafePublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.hidesBackButton = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerName.text = viewModel.playerName
        
        let particles = addParticleView()
        
        particles.alpha = 0
        UIView.animate(withDuration: 2, animations: {
            particles.alpha = 1
        }, completion: {_ in
            self.addCloseButton()
        })
    }
    
    private func addCloseButton(){
        let leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: nil, action: nil)
        bind(leftBarButtonItem.reactive.tap, to: tappedToClose)
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    private func addParticleView() -> SKView{
        
        let skView = SKView(frame: self.view.frame)
        skView.backgroundColor = .clear
        skView.isOpaque = false
        view.insertSubview(skView, belowSubview: playerName)
        
        let scene = SKScene(size: skView.frame.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        
        let path = Bundle.main.path(forResource: "Fireworks", ofType: "sks")
        let fireworksParticle = NSKeyedUnarchiver.unarchiveObject(withFile: path!) as! SKEmitterNode
        
        var position = playerName.center
        position.y = position.y + 64
        fireworksParticle.position = position
        
        scene.addChild(fireworksParticle)
        skView.presentScene(scene)
        
        return skView
    }
}
extension WinnerViewController {
    struct Actions {
        public let tappedToClose: SafeSignal<Void>
    }
    
    var actions: Actions {
        return Actions(
            tappedToClose: tappedToClose.toSignal()
        )
    }
}
