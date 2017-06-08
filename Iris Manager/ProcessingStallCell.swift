//
//  InsertingStallCell.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/25/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit

class ProcessingStallCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.activityIndicator.startAnimating()
    }
}

