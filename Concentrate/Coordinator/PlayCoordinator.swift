//
//  GameCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 07/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit

class PlayCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "PlayCoordinator"
    let presenter: UIViewController
    var childCoordinators: [String : Coordinator] = [:]
    
    init(presenter: UIViewController){
        self.presenter = presenter
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    internal func start(withCallback completion: CoordinatorCallback?) {
        
        let viewController = vendViewController()
        presenter.present(viewController, animated: false) {
            completion?(self)
        }
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    internal func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
    private func vendViewController() -> UIViewController {
        return ViewController()
    }
}
