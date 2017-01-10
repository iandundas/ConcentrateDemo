//
//  Score.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation
import RealmSwift

public class Score: Object {

    public dynamic var id = NSUUID().uuidString
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    public dynamic var playerName: String? = nil
    public dynamic var score: Int = 0
    public dynamic var created = Date()
}
