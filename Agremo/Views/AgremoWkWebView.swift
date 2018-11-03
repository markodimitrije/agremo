//
//  AgremoWkWebView.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 21/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation

class AgremoWkWebView: WKWebView {
    
    var timeElapsed: TimeInterval = 0
    var timer: Timer?
    weak var loadingDelegate: AgremoWkWebViewLoadingDelegate?
    
    //    class func handlesURLScheme(_ urlScheme: String) -> Bool {
    //        return true
    //    }
    
    // ovo je override za init sa SB-a
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        atachProgressObserverAndTimer()
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        atachProgressObserverAndTimer()
    }
    
    private func atachProgressObserverAndTimer() {
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

protocol CoreLocationUpdating {
    mutating func locationUpdated(location: CLLocation)
}

struct AgremoCLUpdater: CoreLocationUpdating {
    
    var previousLocation: CLLocation?
    var webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    // MARK:- API
    
    mutating func locationUpdated(location: CLLocation) {
        
        if shouldUpdateJavaScriptAboutCLChange(actualLocation: location) {
            
            self.updateJavaScriptFunc(in: webView, with: location)
            
            print("update JS, dist change > 1m")
            
            self.previousLocation = location
            
        } else {
            
            print("dont update JS, insufficiant dist change")
            
        }
        
    }
    
    // MARK:- Privates
    
    private func shouldUpdateJavaScriptAboutCLChange(actualLocation: CLLocation) -> Bool {
        
        guard let previousLocation = previousLocation else {return true}
        
        let distance = abs(previousLocation.distance(from: actualLocation))
        
        print("distance between 2 locations = \(distance)")
        
        return distance >= Constants.Location.sugnificantDistToUpdateJSLocationFunc // 1 meter
    }
    
    private func updateJavaScriptFunc(in webView: WKWebView, with location: CLLocation) {
        
        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        
        // nemanja spajic: AgrisensObject. loadMyCurrentLocation --->> LONG-LAT
        let _ = webView.evaluateJavaScript("AgrisensObject.loadMyCurrentLocation(\(long), \(lat));") { (data, err) in
            
            if err == nil {
                print("executeLoadMyCurrentLocationJavaScript.all good...")
            } else {
                print("loadMyCurrentLocation.err = \(err!.localizedDescription)")
            }
        }
        
        
    }
    
}
