//
//  LoadingAssetsViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

class LoadingAssetsViewModel{
    
    let errorMessages = SafePublishSubject<String>()
    let isLoading = Property<Bool>(false)
    
    let loadedPhotos:  Signal<[UIImage], NoError>
    let actions: LoadingAssetsViewController.Actions
    init(actions: LoadingAssetsViewController.Actions, assetCount: Int){
        self.actions = actions
        
        self.loadedPhotos = fetchPhotoAssets(tag: "kitten", count: assetCount)
            .flatMapLatest { fetchImages(assets: $0).retry(times: 2) }
            .feedActivity(into: isLoading)
            .feedError(into: errorMessages)
            .retry(when: actions.tappedRetry)
            .suppressError(logging: true) // already handled
    }
}

class LoadingAssetsViewController: BaseBoundViewController<LoadingAssetsViewModel>{
    
    static func create(viewModelFactory: @escaping (LoadingAssetsViewController) -> LoadingAssetsViewModel) -> LoadingAssetsViewController{
        return create(storyboard: UIStoryboard(name: "LoadingAssets", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! LoadingAssetsViewController
    }
    
    @IBOutlet var activitySpinner: UIActivityIndicatorView!
    @IBOutlet var containerView: UIView!{
        didSet{
            containerView.layer.cornerRadius = 6
        }
    }
    
    fileprivate let retry = SafePublishSubject<Void>()
    
    override func bindTo(viewModel: LoadingAssetsViewModel) {
        bind(viewModel.isLoading, to: activitySpinner.reactive.animating)
        
        viewModel.errorMessages.observeNext { [weak self] (errorMessage) in
            guard let strongSelf = self else {return}
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: { (_) in
                strongSelf.retry.next()
            }))
            strongSelf.present(alert, animated: true, completion: nil)
        }.dispose(in: reactive.bag)
    }
}

extension LoadingAssetsViewController{
    
    struct Actions {
        public let tappedRetry: SafeSignal<Void>
    }
    
    var actions: Actions {
        return Actions(
            tappedRetry: retry.toSignal()
        )
    }
}

