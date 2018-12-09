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
    
    var parentHeightCnstr: NSLayoutConstraint?
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.transform = progressView.transform.scaledBy(x: 1, y: 3)
        }
    }
    
    @IBOutlet weak var filename: UILabel!
    @IBOutlet weak var percentLbl: UILabel!
    
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        
        guard let superview = self.superview else {return}
        
        parentHeightCnstr?.constant = superview.frame.height - 88
        
        //superview.frame = CGRect.init(origin: superview.frame.origin, size: CGSize.init(width: superview.frame.width, height:  ))
        
        self.removeFromSuperview()
    }
    
    @IBAction func showBtnTapped(_ sender: UIButton) {
        print("prikazi file, impelement me")
    }
    
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
    
    func update(info: ProgressViewInfo) {
        progressView.progress = Float(info.percent) / 100 // ovaj je od 0-1 range
        percentLbl.text = "\(info.percent) %"
        filename.text = info.name
    }
    
}

struct ProgressViewInfo {
    var session: URLSession?
    var name: String = "downloading content"
    var percent: Int = 0
    var dismissBtnTxt = ""
    var previewFileBtnTxt: String = ""
}
