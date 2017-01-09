//
//  SelectPlayerViewController.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit
import Bond

class SelectPlayerViewModel<Player: PlayerType> {
    let selectedRows: Property<[Int : Bool]>
    private let selectedRowsSink: Signal<[Int : Bool], NoError>
    
    let goEnabled: SafeSignal<Bool>
    
    private let players: [Player]
    private let actions: SelectPlayerViewController.Actions
    
    init(actions: SelectPlayerViewController.Actions, players: [Player]) {
        self.actions = actions
        self.players = players
        
        self.selectedRows = Property([:])
        self.selectedRowsSink = actions.selectedRow.scan([Int:Bool]()) { (previous, indexPath) -> [Int:Bool] in
            var next = previous
            if let bool = previous[indexPath.row], bool == true {
                next.updateValue(false, forKey: indexPath.row)
            }
            else{
                next.updateValue(true, forKey: indexPath.row)
            }
            return next
        }
        
        self.selectedRowsSink.bind(to: selectedRows)
        
        // Scan the selected rows to see if there are any yet:
        self.goEnabled = selectedRowsSink.scan(0, { (previous, this) -> Int in
            let selectedRows = this.filter { $0.value }
            return selectedRows.count
        }).map {$0 > 0}
        
        self.actions.tappedGo.with(latestFrom: selectedRows).map {_, rows -> [Player] in
            let selectedPlayers = players.enumerated()
                .filter {rows[$0.offset] ?? false} // Match players whos rows were selected
                .map {_, player in player } // strip index, return Player
            return selectedPlayers
        }.observeNext { (players) in
            print("Players: \(players)")
        }
        
        
    }
    
    var rowCount: Int {
        return players.count
    }
    
    func playerName(row: Int) -> String?{
        guard players.count > row else {return nil}
        return players[row].name
    }
}

class PlayerCell: UITableViewCell{
    
    @IBOutlet var playerName: UILabel!
}

class SelectPlayerViewController: BaseBoundViewController<SelectPlayerViewModel<RealPlayer>>, UITableViewDataSource{
    
    public static func create(viewModelFactory: @escaping (SelectPlayerViewController) -> SelectPlayerViewModel<RealPlayer>) -> SelectPlayerViewController{
        return create(storyboard: UIStoryboard(name: "SelectPlayer", bundle: Bundle.main), viewModelFactory: downcast(closure: viewModelFactory)) as! SelectPlayerViewController
    }
    
    @IBOutlet var tableView: UITableView! {
        didSet{
            tableView.dataSource = self
        }
    }
    
    let tappedGo = SafePublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose Your Warriors!"
        
        let rightBarButtonItem = UIBarButtonItem(title: "Go!", style: .done, target: nil, action: nil)
        bind(viewModel.goEnabled, to: rightBarButtonItem.reactive.isEnabled)
        bind(rightBarButtonItem.reactive.tap, to: tappedGo)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    override func bindTo(viewModel: SelectPlayerViewModel<RealPlayer>) {
        viewModel.selectedRows.observeNext { [weak self] _ in
            // TODO be more smart r.e. the rows we update here
            self?.tableView.reloadData()
        }.dispose(in: reactive.bag)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCount
    }
    
    let playerCellID = "PlayerCell"
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerCellID) as! PlayerCell
        
        configure(playerCell: cell, for: indexPath)
        
        return cell
    }
    
    private func configure(playerCell cell: PlayerCell, for indexPath: IndexPath){
        cell.playerName.text = viewModel.playerName(row: indexPath.row)
        
        if let selected = viewModel.selectedRows.value[indexPath.row], selected{
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
    }
}

extension SelectPlayerViewController{
    
    struct Actions {
        public let selectedRow: SafeSignal<IndexPath>
        public let tappedGo: SafeSignal<Void>
    }
    
    var actions: Actions {
        return Actions(
            selectedRow: tableView.reactive.selectedRow,
            tappedGo: tappedGo.toSignal()
        )
    }
}

