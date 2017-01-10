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

struct FakePicture: PictureType, Equatable {
    let name: String
    let id: String = NSUUID().uuidString
    var loadedImage: UIImage{
        return UIImage() // i.e. fake
    }
    func image(size: CGSize) -> Signal<UIImage, String> {
        return Signal.just(loadedImage)
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

