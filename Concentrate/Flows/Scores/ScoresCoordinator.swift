//
//  HighScoresCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond
import RealmSwift

class ScoresCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "ScoresCoordinator"
    let presenter: UINavigationController
    var childCoordinators: [String : Coordinator] = [:]
    
    let shouldDismissCoordinator = SafePublishSubject<Void>()
    
    private let realm = try! Realm()
    private let bag = DisposeBag()
    
    init(presenter: UINavigationController){
        self.presenter = presenter
    }
        
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        let highScoresViewController = HighScoresViewController.create { (viewController) -> HighScoresViewModel in
            let viewModel = HighScoresViewModel(realm: self.realm)
            return viewModel
        }
        
        highScoresViewController.actions.tappedToClose.bind(to: shouldDismissCoordinator)
        
        presenter.viewControllers = [highScoresViewController]
        
        completion?(self)
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
}
