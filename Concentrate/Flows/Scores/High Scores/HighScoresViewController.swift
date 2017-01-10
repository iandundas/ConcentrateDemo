//
//  HighScoresViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 10/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import RealmSwift
import ReactiveKit

class HighScoresViewModel{
    let title = "High Scores"
    
    private let realm: Realm
    private let results: Results<Score>
    
    init(realm: Realm){
        self.realm = realm
        self.results = realm.objects(Score.self).sorted(byProperty: "score", ascending: false)
    }
    
    var rowCount: Int{
        return results.count
    }
    
    func playerName(row: Int) -> String{
        guard let playerName = results[row].playerName else {return ""}
        return playerName
    }
    
    func score(row: Int) -> String{
        return String(results[row].score)
    }
}

class HighScoresViewController: BaseBoundViewController<HighScoresViewModel>, UITableViewDataSource {
    public static func create(viewModelFactory: @escaping (HighScoresViewController) -> HighScoresViewModel) -> HighScoresViewController{
        return create(storyboard: UIStoryboard(name: "HighScores", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! HighScoresViewController
    }
    
    @IBOutlet var tableView: UITableView!{
        didSet{
            tableView.dataSource = self
        }
    }
    
    let tappedToClose = SafePublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
        
        let leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: nil, action: nil)
        bind(leftBarButtonItem.reactive.tap, to: tappedToClose)
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    override func bindTo(viewModel: HighScoresViewModel) {
        
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCount
    }

    let cellID = "HighScoreCellID"
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! HighScoreCell
        
        cell.name.text = viewModel.playerName(row: indexPath.row)
        cell.score.text = viewModel.score(row: indexPath.row)
        
        return cell
    }
}


extension HighScoresViewController {
    struct Actions {
        public let tappedToClose: SafeSignal<Void>
    }
    
    var actions: Actions {
        return Actions(
            tappedToClose: tappedToClose.toSignal()
        )
    }
}


class HighScoreCell: UITableViewCell{
    @IBOutlet var name: UILabel!
    @IBOutlet var score: UILabel!
}
