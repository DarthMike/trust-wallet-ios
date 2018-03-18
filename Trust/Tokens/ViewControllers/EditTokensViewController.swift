// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

class EditTokensViewController: UITableViewController {

    let session: WalletSession
    let storage: TokensDataStore
    let network: TokensNetworkProtocol

    lazy var viewModel: EditTokenViewModel = {
        return EditTokenViewModel(
            network: network,
            storage: storage,
            config: session.config,
            table: tableView
        )
    }()

    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = viewModel.searchPlaceholder
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.sizeToFit()
        searchController.searchBar.backgroundColor = .white
        searchController.searchBar.delegate = self
        return searchController
    }()

    lazy var searchClosure: (String) -> Void = {
        return debounce(delay: .milliseconds(700), action: { (query) in
            self.viewModel.search(token: query)
        })
    }()

    init(
        session: WalletSession,
        storage: TokensDataStore,
        network: TokensNetworkProtocol
    ) {
        self.session = session
        self.storage = storage
        self.network = network

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = viewModel.title
        definesPresentationContext = true
        tabBarController?.definesPresentationContext = true
        configureTableView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.editTokenTableViewCell.name, for: indexPath) as! EditTokenTableViewCell
        cell.delegate = self
        let token = self.viewModel.token(for: indexPath)
        cell.viewModel = EditTokenTableCellViewModel(
            token: token,
            coinTicker: storage.coinTicker(for: token),
            config: session.config
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func configureTableView() {
        tableView.register(R.nib.editTokenTableViewCell(), forCellReuseIdentifier: R.nib.editTokenTableViewCell.name)
        tableView.tableHeaderView = searchController.searchBar
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .white
    }
}

extension EditTokensViewController: EditTokenTableViewCellDelegate {
    func didChangeState(state: Bool, in cell: EditTokenTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        self.viewModel.updateToken(indexPath: indexPath, action: .disable(!state))
    }
}

extension EditTokensViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchClosure(searchBar.text ?? "")
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.searchClosure(searchBar.text ?? "")
    }
}

extension EditTokensViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchClosure(searchController.searchBar.text ?? "")
    }
}
