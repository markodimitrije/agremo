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
    
    weak var delegate: FilePreviewResponding?
    
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
        
        toggleColorsOnPressed(btn: showBtn)
        
        delegate?.hide(sessionIdentifier: sessionIdentifier)
        
        removeProgressView(during: TimeInterval(0))
    }
    
    @IBAction func showBtnTapped(_ sender: UIButton) {
        
        print("prikazi file, impelement me")
        
        toggleColorsOnPressed(btn: showBtn)
        
        delegate?.preview(sessionIdentifier: sessionIdentifier)
        
        // probao u dummy proj (razne fajlove razne const..), ne mogu da resim.. da ne treba na bg thread ? ovo yek nema smisla - ostavi.
        removeProgressView(during: TimeInterval(3))
        
    }
    
    func toggleColorsOnPressed(btn: UIButton) {
        let actualColor = btn.backgroundColor ?? Constants.Colors.progressBar
        btn.backgroundColor = .white
        btn.setTitleColor(.black, for: .normal)
        btn.layer.borderColor = actualColor.cgColor
        btn.layer.borderWidth = 2.0
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
        
        roundBtns()
        
        self.addSubview(view)
    }
    
    private func removeProgressView(during: TimeInterval) {
        
        disableBtns(during: during)
        
        guard let superview = self.superview else {return}
        
        delay(during) { [weak self] in
            guard let sSelf = self else { return }
            sSelf.parentHeightCnstr?.constant = superview.frame.height - CGFloat(Constants.DownloadView.heightWithGap)
            sSelf.removeFromSuperview()
        }
        
    }
    
    private func disableBtns(during: TimeInterval) {
        
        _ = [dismissBtn, showBtn].map { btn in
            btn?.isEnabled = false
            
            UIView.animate(withDuration: during, animations: {
                btn?.alpha = 0.0
            })
        }
        
    }
    
    func update(info: ProgressViewInfo) {
        progressView.progress = Float(info.percent) / 100 // ovaj je od 0-1 range
        //percentLbl.text = info.percent != 100 ? "\(info.percent) %" : (info.filename ?? "")
        percentLbl.text = info.percent <= 100 ? "\(info.percent) %" : (info.filename ?? "")
        statusLbl.text = info.statusDesc
        //showBtn(enable: info.percent == 100)
        showBtn(enable: true) // hard-coded
        dismissBtn.setTitle(info.dismissBtnTxt, for: .normal)
        showBtn.setTitle(info.previewFileBtnTxt, for: .normal)
    }
    
    private func showBtn(enable: Bool) {
        showBtn.isEnabled = enable
        showBtn.alpha = enable ? 1 : 0.5
    }
    
    private func roundBtns() {
        
        _ = [showBtn, dismissBtn].map { (btn) -> Void in
            btn?.layer.cornerRadius = showBtn.bounds.height / 2
        }
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

protocol FilePreviewResponding: class {
    func preview(sessionIdentifier: String)
    func hide(sessionIdentifier: String)
}
