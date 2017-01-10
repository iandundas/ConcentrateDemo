//
//  Coordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 07/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

typealias CoordinatorCallback = (Coordinator) -> Void

protocol Coordinator: NSObjectProtocol{
    var identifier: String {get}
    var presenter: UINavigationController { get }
    var childCoordinators: [String: Coordinator] { get set }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?)
    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?)

    func startChild<T: NSObject>(coordinator: T, callback: CoordinatorCallback?) -> T where T: Coordinator
    
    func stopChild(coordinatorWithIdentifier identifier: String, callback: CoordinatorCallback?)
}

extension Coordinator {
    
    // Default implementations:
    func startChild<T: NSObject>(coordinator: T, callback: CoordinatorCallback?) -> T  where T: Coordinator {
        childCoordinators[coordinator.identifier] = coordinator
        coordinator.start(withCallback: callback)
        return coordinator
    }
    
    func stopChild(coordinatorWithIdentifier identifier: String, callback: CoordinatorCallback? = nil) {
        guard let coordinator = childCoordinators[identifier], let index = childCoordinators.index(forKey: identifier) else {
            fatalError("No such coordinator: \(identifier)")
        }
        
        coordinator.stop(withCallback: { [unowned self] (coordinator) in
            self.childCoordinators.remove(at: index)
            callback?(coordinator)
        })
    }
}
