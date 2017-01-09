//
//  MainCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

class MainCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "MainCoordinator"
    let presenter: UINavigationController
    var childCoordinators: [String : Coordinator] = [:]
    
    let demoPlayers = [
        RealPlayer(name: "😸"),
        RealPlayer(name: "😹"),
        RealPlayer(name: "😼"),
        RealPlayer(name: "😻"),
    ]
    
    private let bag = DisposeBag()
    init(presenter: UINavigationController){
        self.presenter = presenter
        
        presenter.setNavigationBarHidden(false, animated: false)
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        let selectPlayer = SelectPlayerViewController.create { (viewController) -> SelectPlayerViewModel<RealPlayer> in
            return SelectPlayerViewModel(actions: viewController.actions, players: self.demoPlayers)
        }

        presenter.viewControllers = [selectPlayer]
//        presenter.present(selectPlayer, animated: false) {
//            
//        }
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
}
