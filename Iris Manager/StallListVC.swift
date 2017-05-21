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

class StallListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, StallUpdateDelegate, AuthenticationDelegate {

    var stalls = [ Stall ]() {
        didSet {
            self.stalls = stalls.sorted { $0.id > $1.id }
        }
    }

    @IBOutlet weak var stallUpdateStatusIndicator: StatusIndicatorView!
    @IBOutlet weak var tableView:                  UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.stalls = StallPersistence.getAllStalls()

        stallUpdateStatusIndicator.frame.size.height = 0
        self.stallUpdateStatusIndicator.alpha = 0
        stallUpdateStatusIndicator.isHidden = true
        
        Authentication.add(delegate: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        updateStalls()
    }


    //MARK: - StallListVC 
    
    func updateStalls() {
        StallPersistence.updateLocalDatabase(delegate: self)
        showUpdateIndicator()
    }

    @IBAction func addStallButtonPress(_ sender: Any) {
        let alert = UIAlertController(title: "Create Stall", message: "Enter Stall name", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField: UITextField!) in
            textField.placeholder = "Stall name"
        })

        alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.default) { [weak alert] (_) in
            let textField = alert!.textFields!.first!
            let stallName = textField.text ?? ""
            self.addStall(stallName: stallName)
            textField.text = ""
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func addStall(stallName: String) {
        StallPersistence.create(stallName: stallName) { stall in
            self.stalls.append(stall)

            self.tableView.beginUpdates()
            let indexPath = IndexPath(item: self.stalls.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.tableView.endUpdates()
        }
    }
    
    func editStall(newName: String, stall: Stall) {
        
        let index = stalls.index(of: stall)!
        
        let newStall = Stall()
        newStall.id = stall.id
        newStall.lastUpdated = stall.lastUpdated
        newStall.name = newName
        
        StallPersistence.modify(oldStall: stall, newStall: newStall) {
            
            self.stalls[index] = stall
            let indexPath = IndexPath(row: index.distance(to: self.stalls.startIndex), section: 0)

            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
        }
    }
    
    
    func deleteStall(stall: Stall, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        let index = stalls.index(of: stall)!
        StallPersistence.delete(stall: stalls[index], onSuccess: onSuccess, onFailure: onFailure)
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
    
    func showEditStall(for stall: Stall) {
        let alert = UIAlertController(title: "Edit Stall", message: "Enter Stall name", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField: UITextField!) in
            textField.text = stall.name
        })
        
        alert.addAction(UIAlertAction(title: "Create", style: UIAlertActionStyle.default) { [weak alert] (_) in
            let textField = alert!.textFields!.first!
            let stallName = textField.text ?? ""
            self.editStall(newName: stallName, stall: stall)
            textField.text = ""
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }
    
    //MARK: - StallUpdateDelegate
    func onUpdateFinish() {
        log.info("Local Stall database updated.")
        self.stalls = StallPersistence.getAllStalls()
        self.tableView.reloadData()
        
        self.hideUpdateIndicator()
    }
    
    func onUpdateFail() {
        log.error("On Request Error called")
        self.hideUpdateIndicator()
    }

    //MARK: - AuthenticationDelegate
    func onAuthentication() {
        self.updateStalls()
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let stall = stalls[indexPath.row]
        showEditStall(for: stall)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard editingStyle == .delete else {
            return
        }
        
        let stall = stalls[indexPath.row]
        
        let onSuccess = {
            self.stalls.remove(at: indexPath.row)
            
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()
        }

        let onFailure = {
            self.stalls.append(stall)
            self.tableView.reloadData()
        }
        
        self.deleteStall(stall: stall, onSuccess: onSuccess, onFailure: onFailure)
        
        
    }

    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stalls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StallCell", for: indexPath)

        cell.textLabel?.text = stalls[indexPath.row].name

        return cell
    }

}
