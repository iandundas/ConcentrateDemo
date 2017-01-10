//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public class BaseBoundViewController<VM>: UIViewController {
    
    public var viewModel: VM{
        if let viewModel = _viewModel {
            return viewModel as! VM
        } else {
            fatalError("Director must not be accessed before view loads.")
        }
    }
    
    private var _viewModel: AnyObject!
    internal var viewModelFactory: ((BaseBoundViewController) -> VM)!
    
    public init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil, viewModelFactory: @escaping (BaseBoundViewController) -> VM) {
        self.viewModelFactory = viewModelFactory
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public static func create(storyboard: UIStoryboard, viewModelFactory: @escaping (BaseBoundViewController) -> VM) -> BaseBoundViewController {
        let viewController = storyboard.instantiateInitialViewController() as! BaseBoundViewController
        viewController.viewModelFactory = viewModelFactory
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewModel = viewModelFactory(self)
        _viewModel = viewModel as AnyObject
        
        viewModelFactory = nil
        bindTo(viewModel: viewModel)
    }
    
    public func bindTo(viewModel: VM) {}
}   

public func downcast<T, U, D>(closure: @escaping (T) -> D) -> ((U) -> D) {
    return { a in closure(a as! T) }
}
