//
//  Picture.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit


protocol PictureType{
    var id: String {get}
    var loadedImage: UIImage {get}
    func image(size: CGSize) -> Signal<UIImage, String>
}

struct DevPicture: PictureType {
    let id: String
    let loadedImage: UIImage
    
    init(image: UIImage, id: String){
        self.loadedImage = image
        self.id = id
    }
    
    // TODO: future work, designed so that you can give an arbitrary size
    // and it pass back a signal which completes with the correct image
    // (which would be loaded from network or resized on the fly).
    func image(size: CGSize) -> Signal<UIImage, String> {
        return Signal.just(loadedImage)
    }
}
