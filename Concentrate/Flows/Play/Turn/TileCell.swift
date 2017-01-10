//
//  TileCell.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit

class TileCell: UICollectionViewCell {
    @IBOutlet var pictureImageView: UIImageView!
    @IBOutlet var pictureMask: UIView!
    var revealed: Bool = false {
        didSet{
            if revealed {
                pictureMask.alpha = 0
            } else{
                pictureMask.alpha = 1
            }
        }
    }
}
