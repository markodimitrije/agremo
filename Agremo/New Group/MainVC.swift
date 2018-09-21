//
//  MainVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import CoreLocation
import RMessage
import WebKit

class MainVC: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var locationManager: CLLocationManager!
    
    let rControl: RMController = RMController()
    
    override func viewDidLoad() { super.viewDidLoad()
        
        configureDummyBackBtnAndAddItToViewHierarchy()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // prati dokle je stigao sa loading...
        
        showLogoView()
        
        //webView.load(URLRequest.agremo)
        webView.load(URLRequest.agremoTest)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MainVC.applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MainVC.applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
    
    // prijavio sam se kao observer da znam dokle je stigao sa loading
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        print("change = \(change)")
        
        if keyPath == "estimatedProgress" {
            print("webView.estimatedProgress = \(webView.estimatedProgress)")
            // kada je fully loaded ukloni mu logo view
            // treba mi i timer na 1 sec koji broji do 7, i na svakih 1 sec da se proveri da li je 'estimatedProgress' == 1
            // cim je 1 (za <= 7 sec) ukloni mu logoView
            
            // za sada samo ukloni kad je ceo loaded:
            
            if webView.estimatedProgress == 1 {
                self.removeLogoView()
                checkLocationAvailability()
            }
            
        }
    }
    
    @objc func applicationDidBecomeActive() {
        //        showLogoView()
        checkConnectivityWithAgremoBackend()
        checkLocationAvailability()
    }
    
    @objc func applicationDidEnterBackground() {
        //        showLogoView()
    }
    
    @objc func dummyBackBtnIsTapped() {
        
        let yesBtnTapHandler: (UIAlertAction) -> () = { [weak self] action in
            //print("posalji app u bg")
            self?.suspendApp()
        }
        
        guard let alertVC = AlertManager().getAlertFor(alertType: .quitAgremoApp, handler: yesBtnTapHandler) else {return}
        
        self.present(alertVC, animated: true, completion: nil)
        
    }
    
    private func configureDummyBackBtnAndAddItToViewHierarchy() {
        
        let height = ApplicationFrameCalculator.getTotalHeightForNavBarAndStatusBar(vc: self)
        
        let btn = UIButton.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: height, height: height)))
        btn.backgroundColor = .clear
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(btn)
        
        btn.addTarget(self, action: #selector(MainVC.dummyBackBtnIsTapped), for: .touchUpInside)
        
    }
    
    private func requestCoreLocationAuth() {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation() // sada dobijas data u delegate..
        }
        
    }
    
    private func suspendApp() {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    
    private func checkConnectivityWithAgremoBackend() {
        
        //showLogoView()
        
        ServerRequest.sendPingToAgremo { (success, error) in
            
            DispatchQueue.main.async { [weak self] in
                
                if let alertVC = PingAgremoManager().getAlertForResponse(success: success, error: error) {
                    self?.present(alertVC, animated: true, completion: nil)
                } else { // all good
                    // ne radi ti nista, jer treba jos da prodje i agremoMobile (load web view request)
                }
                
            }
            
        }
        
    }
    
    private func showLogoView() {
        
        guard let windowView = UIApplication.view else {return}
        
        if let _ = windowView.subviews.first(where: {$0.tag==12}) {
            return // vec ga prikazujes, izadji...
        }
        
        let agremoLogoView = LogoView.init(frame: self.view.bounds); agremoLogoView.tag = 12
        
        windowView.addSubview(agremoLogoView)
    }
    
    private func removeLogoView() {
        let logoView = UIApplication.view?.subviews.first(where: {$0.tag==12})
        logoView?.removeFromSuperview()
    }
    
    private func checkLocationAvailability() {
        if CLLocationManager.authorizationStatus() != .notDetermined {
            checkCoreLocationAvailability()
        }
    }
    
    private func checkCoreLocationAvailability() {
        if CLLocationManager.authorizationStatus() == .denied {
            
            //rControl.showAgremoTossMessage() // ovo izmesti u drugu neku klasu....
            
            customizeRMessage()
            
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK:- poziva sistem jer si delegate za CoreLocation
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0] as CLLocation
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    
    // MARK:- customize RMessage
    
    private func customizeRMessage() {
        
        var attributedSpec = warningSpec
        attributedSpec.backgroundColor = UIColor.agremoTossMessage ?? .black
        
        attributedSpec.titleColor = .black
        attributedSpec.bodyColor = .black
        
        attributedSpec.iconImage = #imageLiteral(resourceName: "Agremo_icon_44x44")
        
        attributedSpec.timeToDismiss = 5.0
        attributedSpec.durationType = RMessageDuration.timed
        
        let button = UIButton(type: .custom)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.sizeToFit()
        button.setTitle(NSLocalizedString("Strings.Settings", comment: ""), for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(MainVC.tossMsgSettingsPressed), for: .touchUpInside)
        
        rControl.showMessage(withSpec: attributedSpec, atPosition: .navBarOverlay, title: RMessageText.coreLocationUnavailableTitle, body: RMessageText.coreLocationUnavailableMsg, rightView: button)
        
    }
    
    @objc func tossMsgSettingsPressed() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) { // ovo je ok ali root
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let _ = rControl.dismissOnScreenMessage()
        
        //let _ = rControl?.dismissOnScreenMessage() zasto puca ovo ? - u preth podu je radilo...
    }
    
}


extension MainVC: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("webView.shouldStartLoadWith is called")
        return true
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView.didCommit is called")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView.didFinish is called")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("navigation = \(navigation)")
        print("webView.didReceiveServerRedirectForProvisionalNavigation is called")
    }
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        print("webView.v is called")
        return true
    }
    
    
    
    
}


















extension URLRequest {
    static var agremo: URLRequest {
        let url = URL.init(string: "https://app.agremo.com/mobile/#")!
        //return URLRequest.init(url: url)
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobile)
    }
    static var agremoTest: URLRequest {
        let url = URL.init(string: "https://daliznas.com/ios_test")!
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobile)
    }
}

enum TimeOut {
    //static let agremoMobile = TimeInterval.init(0.05)
    static let agremoMobile = TimeInterval.init(7.0)
}

extension UIColor {
    static let agremoTossMessage = UIColor.init("#f7931d")
}

extension RMController {
    
    func showAgremoTossMessage() {
        
        var attributedSpec = warningSpec
        attributedSpec.backgroundColor = UIColor.agremoTossMessage ?? .black
        
        attributedSpec.titleColor = .black
        attributedSpec.bodyColor = .black
        
        attributedSpec.iconImage = #imageLiteral(resourceName: "Agremo_icon_44x44")
        
        attributedSpec.timeToDismiss = 5.0
        attributedSpec.durationType = RMessageDuration.timed
        
        let button = UIButton(type: .custom)
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.sizeToFit()
        button.setTitle(NSLocalizedString("Strings.Settings", comment: ""), for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(MainVC.tossMsgSettingsPressed), for: .touchUpInside)
        
        self.showMessage(withSpec: attributedSpec, atPosition: .navBarOverlay, title: RMessageText.coreLocationUnavailableTitle, body: RMessageText.coreLocationUnavailableMsg, rightView: button)
    }
}
