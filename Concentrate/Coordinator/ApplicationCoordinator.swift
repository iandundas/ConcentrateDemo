//
//  ApplicationCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 07/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit

class ApplicationCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator
    var identifier = "Application"
    let presenter = UIViewController()
    var childCoordinators: [String: Coordinator] = [:]
    
    let window: UIWindow
    let realm = try! Realm()
    private let bag = DisposeBag()
    
    init(window: UIWindow){
        self.window = window
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        
        let play = PlayCoordinator(presenter: presenter)
        _ = startChild(coordinator: play) { (playCoordinator) in
            //
        }
    }
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?){
        fatalError("This should never happen to App Coordinator")
    }
}
