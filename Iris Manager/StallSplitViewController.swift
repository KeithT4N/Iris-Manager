//
//  StallSplitViewController.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/11/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit

class StallSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior
        return true
    }
}

