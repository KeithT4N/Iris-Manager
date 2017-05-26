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
import LKAlertController

class StallListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, StallUpdateDelegate, AuthenticationDelegate {

    var stalls: [(id: Int?, name: String, processing: Bool)] = [] {
        didSet {

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

                //If the ID of the first is greater than the second, stay
                return firstID > secondID
            }
        }
    }

    @IBOutlet weak var stallUpdateStatusIndicator: StatusIndicatorView!
    @IBOutlet weak var tableView:                  UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.stalls = StallPersistence
                .getAllStalls()
                .map { (id: $0.id, name: $0.name, processing: false) }

        stallUpdateStatusIndicator.frame.size.height = 0
        self.stallUpdateStatusIndicator.alpha = 0
        stallUpdateStatusIndicator.isHidden = true

        Authentication.add(delegate: self)

        self.updateStallDatabase()
    }

    //MARK: - StallListVC 

    func updateStallDatabase() {
        StallPersistence.updateLocalDatabase(delegate: self)
        showUpdateIndicator()
    }

    @IBAction func addStallButtonPress(_ sender: Any) {
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

        let onCreateSuccess: (Stall) -> Void = { stall in

            //Find index on array with initial characteristics
            let stallIndex = self.stalls.index { $0.name == stallName && $0.processing && $0.id == nil }!

            //Turn off processing
            self.stalls[stallIndex].processing = false

            //Reload UI
            let indexPath = IndexPath(item: stallIndex, section: 0)
            self.tableView.reloadRows(at: [ indexPath ], with: .fade)

            //Update database
            self.updateStallDatabase()
        }

        let onCreateFail = {
            //Find index on array
            let stallIndex = self.stalls.index { $0.name == stallName && $0.processing && $0.id == nil }!

            //Remove from array
            self.stalls.remove(at: stallIndex)

            //Remove from tableview
            let indexPath = IndexPath(item: stallIndex, section: 0)
            self.tableView.deleteRows(at: [ indexPath ], with: .fade)
        }

        StallPersistence.create(stallName: stallName, onSuccess: onCreateSuccess, onFailure: onCreateFail)

    }

    func editStall(newName: String, id: Int, oldName: String) {
        let index = self.stalls.index { $0.name == oldName && !$0.processing && $0.id == id }!
        self.stalls[index].name = newName //Show changes first
        self.stalls[index].processing = true
        self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .fade)

        let newStall = Stall()
        newStall.id = id
        newStall.name = newName

        let onSuccess = {
            let index = self.stalls.index { $0.name == newName && $0.processing && $0.id == id }!
            self.stalls[index].name = newName
            self.stalls[index].processing = false
            self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0) ], with: .fade)
        }

        let onFailure = {
            let index = self.stalls.index { $0.name == newName && $0.processing && $0.id == id }!
            self.stalls[index].processing = false
            self.tableView.reloadRows(at: [ IndexPath(row: index, section: 0) ], with: .fade)
        }

        StallPersistence.modify(newStall: newStall, onSuccess: onSuccess, onFailure: onFailure)
    }

    func deleteStall(at index: Int) {
        self.stalls[index].processing = true

        let name = self.stalls[index].name
        let id   = self.stalls[index].id! //This should exist. It's impossible otherwise.

        //Update UI
        self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .fade)

        let onSuccess = {
            let index = self.stalls.index { $0.name == name && $0.processing && $0.id == id }!
            self.stalls.remove(at: index)
            self.tableView.deleteRows(at: [ IndexPath(item: index, section: 0) ], with: .automatic)
        }

        let onFailure = {
            let index = self.stalls.index { $0.name == name && $0.processing && $0.id == id }!
            self.stalls[index].processing = false
            self.tableView.reloadRows(at: [ IndexPath(item: index, section: 0) ], with: .automatic)
        }

        StallPersistence.delete(id: id, onSuccess: onSuccess, onFailure: onFailure)
    }

    func hideUpdateIndicator() {

        if stallUpdateStatusIndicator.frame.height == 0 && stallUpdateStatusIndicator.alpha == 0 {
            return
        }

        let animation = {
            self.stallUpdateStatusIndicator.frame.size.height = 0
            self.stallUpdateStatusIndicator.alpha = 0
            self.stallUpdateStatusIndicator.layoutIfNeeded()
        }

        UIView.animate(withDuration: 0.3, animations: animation, completion: { (_) in
            self.stallUpdateStatusIndicator.isHidden = true
        })
    }

    func showUpdateIndicator() {
        stallUpdateStatusIndicator.isHidden = false

        if stallUpdateStatusIndicator.frame.height == 35 && stallUpdateStatusIndicator.alpha == 1 {
            return
        }

        UIView.animate(withDuration: 0.1) {
            self.stallUpdateStatusIndicator.frame.size.height = 35
            self.stallUpdateStatusIndicator.alpha = 1
            self.stallUpdateStatusIndicator.layoutIfNeeded()
        }
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
    func onUpdateFinish() {
        log.info("Local Stall database updated.")
        self.stalls = StallPersistence
                .getAllStalls()
                .map { ($0.id, $0.name, false) }

        self.tableView.reloadData()
        self.hideUpdateIndicator()
    }

    func onUpdateFail() {
        log.error("On Request Error called")
        self.hideUpdateIndicator()
    }

    //MARK: - AuthenticationDelegate
    func onAuthentication() {
        self.updateStallDatabase()
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

}
