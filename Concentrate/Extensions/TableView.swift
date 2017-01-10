//
//  TableView.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

extension Reactive where Base: UITableView{
    var selectedRow: Signal<IndexPath, NoError> {
        return delegate.signal(for: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) { (subject: PublishSubject<IndexPath, NoError>, _: UITableView, indexPath: NSIndexPath) in
            subject.next(indexPath as IndexPath)
        }
    }
}
