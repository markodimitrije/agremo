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
    weak var swipeDelegate: StackScrolling?
    
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
        
        delegate?.hide(sessionIdentifier: sessionIdentifier, isFinished: isFinished)
        
        removeProgressView(during: TimeInterval(0))
    }
    
    @IBAction func showBtnTapped(_ sender: UIButton) {
        
        toggleColorsOnPressed(btn: showBtn)
        
        delegate?.preview(sessionIdentifier: sessionIdentifier)
        
        // probao u dummy proj (razne fajlove razne const..), ne mogu da resim.. da ne treba na bg thread ? ovo yek nema smisla - ostavi.
        removeProgressView(during: TimeInterval(5))
        
    }
    
    private var lastSavedPercent: Int = 0
    private var isFinished: Bool {
        return lastSavedPercent >= 98 // treba 100, ostavljam za svaki slucaj (desava se da ne update na 99 ?!?)
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
        
        attachSwipeHandledByParentView(toView: view) // onProgressViewScroll(sender
        
        self.addSubview(view)
    }
    
    private func attachSwipeHandledByParentView(toView view: UIView) {
        let leftGr = UISwipeGestureRecognizer.init(target: self, action: #selector(self.onProgressViewScroll(_:)))
        leftGr.direction = .left
        
        let rightGr = UISwipeGestureRecognizer.init(target: self, action: #selector(self.onProgressViewScroll(_:)))
        rightGr.direction = .right
        
        view.addGestureRecognizers(gestureRecognizers: [leftGr, rightGr])

    }
    
    @objc func onProgressViewScroll(_ gesture: UISwipeGestureRecognizer) {
        swipeDelegate?.onProgressViewScroll(gesture.direction) // dodaj ga parentu...
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
        
//      _ = [dismissBtn, showBtn].map { btn in
//            btn?.isEnabled = false
//
//            UIView.animate(withDuration: during, animations: {
//                btn?.alpha = 0.0
//            })
//        }

        UIView.animate(withDuration: during, animations: { [weak self] in
            guard let sSelf = self else {return}
            sSelf.alpha = 0.0
        })
        
    }
    
    func update(info: ProgressViewInfo) {
        
        if info.percent > self.lastSavedPercent { // ne dozvoljavam da ga sync sa losim data, ili paralelnim download-om (trebao si cancel web request..)
            
            lastSavedPercent = info.percent
            
            progressView.progress = Float(info.percent) / 100 // ovaj je od 0-1 range
            //percentLbl.text = info.percent != 100 ? "\(info.percent) %" : (info.filename ?? "")
            percentLbl.text = "\(info.percent) %"
            statusLbl.text = info.statusDesc
            showBtn(enable: info.percent >= 98)
            dismissBtn.setTitle(info.dismissBtnTxt, for: .normal)
            showBtn.setTitle(info.previewFileBtnTxt, for: .normal)
            
        }
        
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
    func hide(sessionIdentifier: String, isFinished: Bool)
}

protocol StackScrolling: class {
    func onProgressViewScroll(_ direction: UISwipeGestureRecognizerDirection)
}
