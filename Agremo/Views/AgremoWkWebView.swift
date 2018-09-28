//
//  AgremoWkWebView.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 21/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import WebKit

class AgremoWkWebView: WKWebView {
    
    var timeElapsed: TimeInterval = 0
    var timer: Timer?
    weak var loadingDelegate: AgremoWkWebViewLoadingDelegate?
    
    //    class func handlesURLScheme(_ urlScheme: String) -> Bool {
    //        return true
    //    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // prati dokle je stigao sa loading...
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(AgremoWkWebView.count),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            
            print("AgremoWkWebView.estimatedProgress = \(self.estimatedProgress)")
            
        }
    }
    
    // MARK:- objc za Selector
    @objc func count() { print("time is = \(timeElapsed)")
        
        timeElapsed += 1
        
        if timeElapsed >= Agremo.TimeOut.agremoMobileLoadContent { // ako je isteklo 7 sec
            
            loadingDelegate?.webView(self, didFinishLoading: false)
            
            timer?.invalidate()
            
        } else {
            
            if self.estimatedProgress > Constants.AgremoWebView.estimatedProgressLimit {
                
                print("javi notifikacijom da je all good")
                
                loadingDelegate?.webView(self, didFinishLoading: true)
                
                timer?.invalidate()
                
            } else { print("just wait, vreme nije isteklo....")
                
            }
            
        }
        
    }
}


