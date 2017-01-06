//
//  FakePicture.swift
//  Concentrate
//
//  Created by Ian Dundas on 06/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit
import UIKit

@testable import Concentrate

/* 
 protocol Picture{
     func image(size: CGSize) -> Signal<UIImage, String>
 }
 */

struct FakePicture: PictureType {
    let name: String
    
    func image(size: CGSize) -> Signal<UIImage, String> {
        return Signal.just(UIImage())
    }
}
func ==(a: FakePicture, b: FakePicture) -> Bool{
    return a.name == b.name
}
func !=(a: FakePicture, b: FakePicture) -> Bool{
    return !(a == b)
}

struct FakePlayer: PlayerType {
    let name: String
}
//
//func ==(a: FakePlayer, b: FakePlayer) -> Bool {
//    return a.name == b.name
//}
