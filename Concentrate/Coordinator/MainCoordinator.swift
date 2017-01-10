//
//  MainCoordinator.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

enum DifficultyLevel: Int{
    case easy = 8
    case hard = 14
}

class MainCoordinator: NSObject, Coordinator{
    
    // MARK: Coordinator:
    let identifier = "MainCoordinator"
    let presenter: UINavigationController
    var childCoordinators: [String : Coordinator] = [:]
    
    let demoPlayers = [
        RealPlayer(name: "😸"),
        RealPlayer(name: "😹"),
        RealPlayer(name: "😼"),
        RealPlayer(name: "😻"),
    ]
    
    let playersWishingToPlayGame = SafePublishSubject<[RealPlayer]>()
    
    private let bag = DisposeBag()
    init(presenter: UINavigationController){
        self.presenter = presenter
        super.init()
        
        presenter.setNavigationBarHidden(false, animated: false)
        
        let waitForAssetLoading: (Int) -> SafeSignal<[UIImage]> = { [weak self] imageCount in
            guard let strongSelf = self else {return Signal.never()}
            return SafeSignal { observer in
                let bag = DisposeBag()
                
                let viewController = LoadingAssetsViewController.create { (viewController) -> LoadingAssetsViewModel in
                    let viewModel = LoadingAssetsViewModel(actions: viewController.actions, assetCount: imageCount)
                    
                    viewModel.loadedPhotos.observeNext(with: { (imagesFromNetwork: [UIImage]) in
                        strongSelf.presenter.dismiss(animated: true, completion: {
                            observer.next(imagesFromNetwork)
                        })
                    }).dispose(in: bag)
                    
                    return viewModel
                }
                
                viewController.modalPresentationStyle = .overCurrentContext
                strongSelf.presenter.present(viewController, animated: true, completion: nil)
                
                return bag
            }
        }
        
        let waitForDifficultySelection = SafeSignal<DifficultyLevel>{ [weak self] observer in
            let bag = DisposeBag()
            guard let strongSelf = self else {return bag}
            
            let actionSheet = UIAlertController(title: "Select Difficulty", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Easy", style: .default, handler: { (_) in
                observer.next(.easy)
            }))
            actionSheet.addAction(UIAlertAction(title: "Hard", style: .default, handler: { (_) in
                observer.next(.hard)
            }))
            
            let barButtonItem = strongSelf.presenter.viewControllers.last?.navigationItem.rightBarButtonItem
            actionSheet.popoverPresentationController?.barButtonItem = barButtonItem
            strongSelf.presenter.present(actionSheet, animated: true, completion: nil)
            
            return bag
        }
        
        playersWishingToPlayGame
            .flatMapLatest { (players) -> SafeSignal<(players: [RealPlayer], level: DifficultyLevel)> in
                return SafeSignal<(players: [RealPlayer], level: DifficultyLevel)> { observer in
                    let bag = DisposeBag()
                    waitForDifficultySelection.observeNext(with: { (difficultyLevel: DifficultyLevel) in
                        observer.next(players: players, level: difficultyLevel)
                    }).dispose(in: bag)
                    return bag
                }
            }
            .flatMapLatest { (players: [RealPlayer], level: DifficultyLevel) -> SafeSignal<(players: [RealPlayer], images: [UIImage])> in
                return SafeSignal<(players: [RealPlayer], images: [UIImage])> { observer in
                    let disposable = DisposeBag()
                    
                    waitForAssetLoading(level.rawValue).observeNext(with: { (images: [UIImage]) in
                        observer.next(players: players, images: images)
                    }).dispose(in: disposable)
                    
                    return disposable
                }
            }
            .observeNext { [weak self] (players: [RealPlayer], images: [UIImage]) in
                guard let strongSelf = self else {return}

                let pictures = images.enumerated().map { DevPicture(image: $0.element, id: String($0.offset)) }
                
                let modalNavController = UINavigationController()
                
                let playCoord = PlayCoordinator(presenter: modalNavController, players: players, pictures: pictures)
                _ = strongSelf.startChild(coordinator: playCoord) { (coordinator) in
                    strongSelf.presenter.present(modalNavController, animated: true, completion: nil)
                }
                
            }.dispose(in: bag)
    }
    
    /// Tells the coordinator to create its initial view controller and take over the user flow.
    func start(withCallback completion: CoordinatorCallback?) {
        
        let selectPlayer = SelectPlayerViewController.create { (viewController) -> SelectPlayerViewModel<RealPlayer> in
            let viewModel = SelectPlayerViewModel(actions: viewController.actions, players: self.demoPlayers)
            viewModel.didChoosePlayers.bind(to: self.playersWishingToPlayGame)
            return viewModel
        }
        
        presenter.viewControllers = [selectPlayer]
    }

    
    /// Tells the coordinator that it is done and that it should rewind the view controller state to where it was before `start` was called.
    func stop(withCallback completion: CoordinatorCallback?) {
        presenter.dismiss(animated: true){
            completion?(self)
        }
    }
    
}
