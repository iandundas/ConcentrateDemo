//
//  CollectionView.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

extension Reactive where Base: UICollectionView{
    var selectedCell: Signal<Int, NoError> {
        return delegate.signal(for: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:))) { (subject: PublishSubject<Int, NoError>, _: UICollectionView, indexPath: NSIndexPath) in
            subject.next(indexPath.row)
        }
    }
}
