//
//  ProgressView.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 08/12/2018.
//  Copyright © 2018 Agremo. All rights reserved.
//

import Foundation

import UIKit

class DownloadProgressView: UIView {
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        self.removeFromSuperview()
    }
    
    @IBAction func showBtnTapped(_ sender: UIButton) {
        print("prikazi file, impelement me")
    }
    
    var filename: String? // ovo je jako vazno da ti neko javi..
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }
    private func loadViewFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "DownloadProgressView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(view)
    }
    
}
