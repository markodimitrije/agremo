//
//  MainVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit; import CoreLocation; import RMessage; import WebKit

class MainVC: UIViewController, CLLocationManagerDelegate, AgremoWkWebViewLoadingDelegate {
    
    @IBOutlet weak var webView: AgremoWkWebView! // WKWebView
    
    var locationManager: CLLocationManager!
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        configureDummyBackBtnAndAddItToViewHierarchy()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        webView.uiDelegate = self; webView.navigationDelegate = self; webView.loadingDelegate = self
        
        showLogoView()
        
        webView.load(URLRequest.agremo)
        //webView.load(URLRequest.agremoTest)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationSubscriber.startToObserveNotifications(onListener : self, dict: observeNotificationsDict)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationSubscriber.stopToObserveNotifications(onListener : self, names: [.UIApplicationDidBecomeActive,.UIApplicationDidEnterBackground])
    }
    
    @objc func applicationDidBecomeActive() {
        checkConnectivityWithAgremoBackend()
        checkLocationAvailability()
    }
    
    @objc func applicationDidEnterBackground() {
        
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
    
    fileprivate func removeLogoView() {
        let logoView = UIApplication.view?.subviews.first(where: {$0.tag==12})
        logoView?.removeFromSuperview()
    }
    
    fileprivate func checkLocationAvailability() {
        if CLLocationManager.authorizationStatus() != .notDetermined {
            checkCoreLocationAvailability()
        }
    }
    
    private func checkCoreLocationAvailability() {
        
        if CLLocationManager.authorizationStatus() == .denied {
            // proveri da li je slucajno neki alert na screen, ako da, nemoj da se prikazujes !!!
            if self.presentedViewController == nil { // nije alert ili neko ko zahteva user attention
                RMessage.Agremo.showCoreLocationWarningMessage()
            }
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


// MARK: Protocol + implementacija od strane MainVC

protocol AgremoWkWebViewLoadingDelegate: class {
    func webView(_ webView: WKWebView, didFinishLoading success: Bool)
}

extension AgremoWkWebViewLoadingDelegate where Self: MainVC {
    func webView(_ webView: WKWebView, didFinishLoading success: Bool) {
        
        if success {
            
            self.removeLogoView()
            self.checkLocationAvailability()
            
        } else {
            
            let alertVC = AlertManager().getAlertFor(alertType: .appLoadingToSlow) { (action) in
                self.removeLogoView()
            }
            
            guard alertVC != nil else {return}
            
            self.present(alertVC!, animated: true, completion: nil)
        }
    }
}
