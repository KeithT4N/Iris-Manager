//
//  StatusIndicatorView.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/14/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit

@IBDesignable
class StatusIndicatorView: UIView {
    // MARK: - Initializers
    
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBInspectable var statusName: String? {
        get {
            return statusLabel.text
        }
        
        set {
            statusLabel.text = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    // MARK: - Private Helper Methods

    // Performs the initial setup.
    private func setupView() {
        
        let view = viewFromNibForClass()
        view.frame = bounds

        // Auto-layout stuff.
        view.autoresizingMask = [ UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight ]

        // Show the view.
        addSubview(view)
    
    }
    
    private func viewFromNibForClass() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
       
        return view
    }
    
}

