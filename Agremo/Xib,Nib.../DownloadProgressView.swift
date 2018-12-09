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
    var sessionIdentifier = ""
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.transform = progressView.transform.scaledBy(x: 1, y: 3)
        }
    }
    
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var percentLbl: UILabel!
    @IBOutlet weak var dismissBtn: UIButton!
    @IBOutlet weak var showBtn: UIButton! {
        didSet {
            showBtn(enable: false)
        }
    }
    
    
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        
        guard let superview = self.superview else {return}
        
        parentHeightCnstr?.constant = superview.frame.height - CGFloat(Constants.DownloadView.heightWithGap)
        
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
    
    convenience init(frame: CGRect, sessionIdentifier: String) {
        self.init(frame: frame)
        self.sessionIdentifier = sessionIdentifier
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
        percentLbl.text = info.percent != 100 ? "\(info.percent) %" : (info.filename ?? "")
        statusLbl.text = info.statusDesc
        showBtn(enable: info.percent == 100)
        dismissBtn.setTitle(info.dismissBtnTxt, for: .normal)
        showBtn.setTitle(info.previewFileBtnTxt, for: .normal)
    }
    
    private func showBtn(enable: Bool) {
        showBtn.isEnabled = enable
        showBtn.alpha = enable ? 1 : 0.5
    }
    
}

struct ProgressViewInfo {
    var session: URLSession?
    var statusDesc: String = ""
    var percent: Int = 0
    var filename: String?
    var dismissBtnTxt = ""
    var previewFileBtnTxt: String = ""
}
