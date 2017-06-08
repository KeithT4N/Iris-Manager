//
//  StallListViewController.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/3/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftMessages
import DZNEmptyDataSet
import LKAlertController

class StallListVC: UITableViewController,
                   UISearchBarDelegate,
                   StallUpdateDelegate,
                   DZNEmptyDataSetSource,
                   DZNEmptyDataSetDelegate {

    //Computed property that determines if searchbar is active
    private var isSearching:  Bool {
        guard let searchText = searchBar.text else {
            return false
        }

        return !searchText.isEmpty
    }
    //Computed property. This is always what's on display on the TableView.
    private var displayArray: [(id: Int?, name: String, processing: Bool)] {
        return isSearching ? filteredStalls : stalls
    }

    //Search query results
    private var filteredStalls: [(id: Int?, name: String, processing: Bool)] {
        guard let searchText = searchBar.text else {
            return stalls //No filter means everything
        }

        return stalls.filter { stall in
            return stall.name.lowercased().contains(searchText.lowercased())
        }
    }

    //All stalls
    private var stalls: [(id: Int?, name: String, processing: Bool)] = [] {
        didSet {

            if self.stalls.isEmpty {
                self.tableView.reloadEmptyDataSet()
                //TODO: Hide searchbar if not hidden by EmptyDataSet
                return //We don't need to sort an empty array
            }

            //Sort by ID, nils go last
            self.stalls = stalls.sorted { first, second in

                //If the ID of the first is nil, send it back
                guard let firstID = first.id else {
                    return false
                }

                //If the ID of the second is nil, but the first isn't, stay
                guard let secondID = second.id else {
                    return true
                }

                //If the ID of the first is less than the second, stay
                return firstID < secondID
            }
        }
    }

    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        StallUpdateManager.delegate = self

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.stalls = StallPersistence
                .getAllStalls()
                .map { (id: $0.id, name: $0.name, processing: false) }

        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.searchBar.delegate = self
        self.tableView.tableFooterView = UIView()
    }

    //MARK: - StallListVC
    @IBAction func addStallButtonPress(_ sender: Any) {
        showAddStall()
    }

    func showAddStall() {
        var textField = UITextField()
        textField.placeholder = "Stall name"

        Alert(title: "Create Stall", message: "Enter Stall Name")
                .addTextField(&textField)
                .addAction("Cancel", style: .cancel) { _ in
                    textField.text = ""
                }
                .addAction("Create", style: .default) { _ in
                    let stallName = textField.text ?? ""
                    self.addStall(stallName: stallName)
                    textField.text = ""
                }
                .show()

    }

    func addStall(stallName: String) {
        //Must go before; Inserting row at the endIndex of current array
        let indexPath = IndexPath(item: self.stalls.endIndex, section: 0)
        self.stalls.append((name: stallName, processing: true, id: nil))

        if (!isSearching) {
            //Do not append when searching
            self.tableView.insertRows(at: [ indexPath ], with: .bottom)
        }

        StallPersistence.create(stallName: stallName, onFailure: {
            //Find index on array
            let stallIndex = self.stalls.index { $0.name == stallName && $0.processing && $0.id == nil }!

            //Remove from array
            self.stalls.remove(at: stallIndex)

            //Remove from tableview, but only if not searching.
            //Searching users won't be able to interact anyway since it's processing.
            //TODO: Remove from search results
            if !self.isSearching {
                let indexPath = IndexPath(item: stallIndex, section: 0)
                self.tableView.deleteRows(at: [ indexPath ], with: .fade)
            }
        })
    }

    func editStall(newName: String, id: Int, oldName: String) {
        let index = self.stalls.index { $0.id == id }!

        self.stalls[index].name = newName
        self.stalls[index].processing = true

        let newStall = Stall()
        newStall.id = id
        newStall.name = newName

        let onFailure = {
            //Index may have changed, should recompute.
            let index = self.stalls.index { $0.id == id }!
            self.stalls[index].name = oldName
            self.stalls[index].processing = false

            //TODO: Remove from search results if searching
            if !self.isSearching {
                self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0) ], with: .fade)
            }
        }

        StallPersistence.modify(newStall: newStall, onFailure: onFailure)

        //Show changes instantly.
        guard let displayIndex = self.displayArray.index(where: { $0.id == id }) else {
            print("Not in search index")
            //Presumably not in search array.
            return
        }

        self.tableView.reloadRows(at: [ IndexPath(item: displayIndex, section: 0) ], with: .fade)


    }

    fileprivate func deleteStall(id: Int) {
        let index = stalls.index { $0.id == id }!
        self.stalls[index].processing = true

        let onFailure = {
            let index = self.stalls.index { $0.id == id }!
            self.stalls[index].processing = false

            //TODO: Remove from search result if searching
            if !self.isSearching {
                self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .automatic)
            }
        }

        StallPersistence.delete(id: id, onFailure: onFailure)

        //Update UI
        guard let displayIndex = self.displayArray.index(where: { $0.id == id }) else {
            //Presumably not in search results
            return
        }

        self.tableView.reloadRows(at: [ IndexPath(item: displayIndex, section: 0) ], with: .fade)
    }

    fileprivate func showEditStall(id: Int, oldName: String) {
        var textField = UITextField()
        textField.text = oldName
        textField.placeholder = "Stall name"

        Alert(title: "Rename Stall", message: "Enter Stall Name")
                .addTextField(&textField)
                .addAction("Cancel", style: .cancel) { _ in
                    textField.text = ""
                }
                .addAction("Rename", style: .default) { _ in
                    let stallName = textField.text ?? ""
                    self.editStall(newName: stallName, id: id, oldName: oldName)
                    textField.text = ""
                }
                .show()
    }

    //MARK: - StallUpdateDelegate
    func didReceiveBulkUpdate() {
        self.stalls = StallPersistence.getAllStalls().map { (id: $0.id, name: $0.name, processing: false) }
        self.tableView.reloadData()
    }

    func stallIsCreated(stall: Stall) {
        /*
        Upon creation, addStall(stallName: String) appends a stall into the stall array.
        If the stallIndex is not nil, it means the stall was created from this app.
        */
        if let stallIndex = self.stalls.index(where: { $0.name == stall.name && $0.processing && $0.id == nil }) {
            //Get displayIndex before modifying the item
            let displayIndex = self.displayArray.index(where: { $0.name == stall.name && $0.processing })

            //Turn off processing
            self.stalls[stallIndex].processing = false

            //Assign the ID
            self.stalls[stallIndex].id = stall.id

            //Then reload at displayIndex if not null
            if let displayIndex = displayIndex  {
                let indexPath = IndexPath(item: displayIndex, section: 0)
                self.tableView.reloadRows(at: [ indexPath ], with: .fade)
            }
            return
        }

        //If we're here, that means the stall was created somewhere else
        let indexPath = IndexPath(item: self.stalls.endIndex, section: 0)
        self.stalls.append((id: stall.id, name: stall.name, processing: false))

        if !isSearching {
            self.tableView.insertRows(at: [ indexPath ], with: .automatic)
        }
    }

    func stallIsModified(stall: Stall) {
        //Find index on displayArray and reload on that index
        let updateIfShowing = {
            if let displayIndex = self.displayArray.index(where: { $0.id == stall.id }) {
                let indexPath = IndexPath(row: displayIndex, section: 0)
                self.tableView.reloadRows(at: [ indexPath ], with: .fade)
            }
        }

        /*
        Upon modification, editStall(newName: String, id: Int, oldName: String)appends a stall
        into the stall array. If the stallIndex is not nil, it means the stall was created from this app.
        */
        if let stallIndex = self.stalls.index(where: { $0.name == stall.name && $0.processing && $0.id == nil }) {
            self.stalls[stallIndex].name = stall.name
            self.stalls[stallIndex].processing = false

            updateIfShowing()
            return
        }

        //If we're here, it means the stall was modified somewhere else
        let stallIndex = self.stalls.index { $0.id == stall.id }!
        self.stalls[stallIndex] = (id: stall.id, name: stall.name, processing: false)

        //If displaying, update.
        updateIfShowing()
    }

    func stallIsDeleted(id: Int) {
        let index = self.stalls.index { $0.id == id }!

        //Get index before removal - it's a computed property.
        let displayIndex = displayArray.index(where: { $0.id == id })
        self.stalls.remove(at: index)

        //If showing, remove.
        if let displayIndex = displayIndex {
            let indexPath = IndexPath(item: displayIndex, section: 0)
            self.tableView.deleteRows(at: [ indexPath ], with: .automatic)
        }
    }


    //MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO
    }

    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            let stall = self.displayArray[index.row]
            self.deleteStall(id: stall.id!)

            //Resign UITableViewRowAction
            tableView.setEditing(false, animated: true)
        }

        let rename = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            let stall = self.displayArray[index.row]
            self.showEditStall(id: stall.id!, oldName: stall.name)

            //Resign UITableViewRowAction
            tableView.setEditing(false, animated: true)
        }

        //Green: UIColor(red:0.32, green:0.85, blue:0.42, alpha:1.0)
        rename.backgroundColor = .lightGray

        return [ delete, rename ]
    }

    //MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let stall = displayArray[indexPath.row]
        return !stall.processing //Cannot edit processing stalls
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let stall = displayArray[indexPath.row]

        if stall.processing {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProcessingStallCell",
                                                     for: indexPath) as! ProcessingStallCell
            cell.label.text = stall.name
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StallCell", for: indexPath)
            cell.textLabel?.text = stall.name
            return cell
        }

    }

    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }

    //MARK: - DZNEmptyDataSetSource
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
        return NSAttributedString(string: "There doesn't seem to be anything here.")
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
        return NSAttributedString(string: "")
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return nil
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        return NSAttributedString(string: "Create stall", attributes: [
                NSFontAttributeName : UIFont.systemFont(ofSize: 17),
                NSForegroundColorAttributeName : self.view.tintColor
        ])
    }

    //MARK: - DZNEmptyDataSetDelegate
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.stalls.isEmpty
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTap button: UIButton) {
        showAddStall()
    }

}
