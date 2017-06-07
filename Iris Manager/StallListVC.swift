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

class StallListVC: UIViewController,
                   UITableViewDataSource,
                   UITableViewDelegate,
                   StallUpdateDelegate,
                   DZNEmptyDataSetSource,
                   DZNEmptyDataSetDelegate {

    var stalls: [(id: Int?, name: String, processing: Bool)] = [] {
        didSet {

            if self.stalls.isEmpty {
                self.tableView.reloadEmptyDataSet()
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

    @IBOutlet weak var tableView: UITableView!

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

        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [ indexPath ], with: .bottom)
        self.tableView.endUpdates()

        StallPersistence.create(stallName: stallName, onFailure: {
            //Find index on array
            let stallIndex = self.stalls.index { $0.name == stallName && $0.processing && $0.id == nil }!

            //Remove from array
            self.stalls.remove(at: stallIndex)

            //Remove from tableview
            let indexPath = IndexPath(item: stallIndex, section: 0)
            self.tableView.deleteRows(at: [ indexPath ], with: .fade)
        })
    }

    func editStall(newName: String, id: Int, oldName: String) {
        let index = self.stalls.index { $0.name == oldName && !$0.processing && $0.id == id }!
        self.stalls[index].name = newName //Show changes first
        self.stalls[index].processing = true
        self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .fade)

        let newStall = Stall()
        newStall.id = id
        newStall.name = newName

        let onFailure = {
            let index = self.stalls.index { $0.name == newName && $0.processing && $0.id == id }!
            self.stalls[index].name = oldName
            self.stalls[index].processing = false
            self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0) ], with: .fade)
        }

        StallPersistence.modify(newStall: newStall, onFailure: onFailure)
    }

    func deleteStall(at index: Int) {
        self.stalls[index].processing = true

        let name = self.stalls[index].name
        let id   = self.stalls[index].id! //This should exist. It's impossible otherwise.

        //Update UI
        self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .fade)

        let onFailure = {
            let index = self.stalls.index { $0.name == name && $0.processing && $0.id == id }!
            self.stalls[index].processing = false
            self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .automatic)
        }

        StallPersistence.delete(id: id, onFailure: onFailure)
    }

    func showEditStall(stallID: Int, oldName: String) {
        var textField = UITextField()
        textField.text = oldName
        textField.placeholder = "Stall name"

        Alert(title: "Edit Stall", message: "Enter Stall Name")
                .addTextField(&textField)
                .addAction("Cancel", style: .cancel) { _ in
                    textField.text = ""
                }
                .addAction("Create", style: .default) { _ in
                    let stallName = textField.text ?? ""
                    self.editStall(newName: stallName, id: stallID, oldName: oldName)
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
            //Turn off processing
            self.stalls[stallIndex].processing = false
            
            //Assign the ID
            self.stalls[stallIndex].id = stall.id

            //Reload UI
            let indexPath = IndexPath(item: stallIndex, section: 0)
            self.tableView.reloadRows(at: [ indexPath ], with: .fade)
            return
        }

        //If we're here, that means the stall was created somewhere else
        let indexPath = IndexPath(item: self.stalls.endIndex, section: 0)
        self.stalls.append((id: stall.id, name: stall.name, processing: false))
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }

    func stallIsModified(stall: Stall) {
        /*
        Upon modification, editStall(newName: String, id: Int, oldName: String)appends a stall
        into the stall array. If the stallIndex is not nil, it means the stall was created from this app.
        */
        if let stallIndex = self.stalls.index(where: { $0.name == stall.name && $0.processing && $0.id == nil }) {
            self.stalls[stallIndex].name = stall.name
            self.stalls[stallIndex].processing = false

            let indexPath = IndexPath(row: stallIndex, section: 0)
            self.tableView.reloadRows(at: [ indexPath ], with: .fade)
            return
        }

        //If we're here, it means the stall was modified somewhere else
        let stallIndex = self.stalls.index { $0.id == stall.id }!
        self.stalls[stallIndex] = (id: stall.id, name: stall.name, processing: false)

        let indexPath = IndexPath(row: stallIndex, section: 0)
        self.tableView.reloadRows(at: [ indexPath ], with: .fade)
    }

    func stallIsDeleted(id: Int) {
        let stallIndex = self.stalls.index { $0.id == id }!
        self.stalls.remove(at: stallIndex)

        let indexPath = IndexPath(item: stallIndex, section: 0)
        self.tableView.deleteRows(at: [ indexPath ], with: .automatic)
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let stall = stalls[indexPath.row]
        showEditStall(stallID: stall.id!, oldName: stall.name) //Stall ID should exist
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else {
            return
        }

        self.deleteStall(at: indexPath.row)
    }

    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stalls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let stall = self.stalls[indexPath.row]

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
