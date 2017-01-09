//
//  AppDelegate.swift
//  Concentrate
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var applicationCoordinator: ApplicationCoordinator = {
        return ApplicationCoordinator(window: self.window!)
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        configureRealm()
        
        applicationCoordinator.start { (_) in
            // 
        }
        
        return true
    }
    
    private func configureRealm(){
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL
        print("Realm initialised: \(realmURL!)")
    }
}

