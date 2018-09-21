//
//  MainVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit; import CoreLocation; import RMessage; import WebKit

class MainVC: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var webView: AgremoWkWebView! // WKWebView
    
    var locationManager: CLLocationManager!
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        configureDummyBackBtnAndAddItToViewHierarchy()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        webView.uiDelegate = self; webView.navigationDelegate = self
        
        // ako si ugasio observer method na sebi, moras i prijavu sebe u suprotnom imas SIGABRT!
        //webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // prati dokle je stigao sa loading...
        
//        showLogoView()
        
        webView.load(URLRequest.agremo)
        //webView.load(URLRequest.agremoTest)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationSubscriber.startToObserveNotifications(onListener : self, dict: observeNotificationsDict)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationSubscriber.stopToObserveNotifications(onListener : self, names: [.UIApplicationDidBecomeActive,.UIApplicationDidEnterBackground])
    }
    /*
    // prijavio sam se kao observer da znam dokle je stigao sa loading
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        //print("change = \(change)")
        
        if keyPath == "estimatedProgress" { print("webView.estimatedProgress = \(webView.estimatedProgress)")
            // kada je fully loaded ukloni mu logo view
            // treba mi i timer na 1 sec koji broji do 7, i na svakih 1 sec da se proveri da li je 'estimatedProgress' == 1
            // cim je 1 (za <= 7 sec) ukloni mu logoView
            
            // za sada samo ukloni kad je ceo loaded:

            let logoViewAction = loadingUrlIsFastEnough(time: 2, timeLimit: Int(TimeOut.agremoMobile), progress: 0.1)
            
            switch logoViewAction {
            case .wait: break
            case .removeWithAlert:
                guard let alertVC = AlertManager().getAlertFor(alertType: .appLoadingToSlow, handler: { (action) in
                    self.removeLogoView()
                }) else {return} // trebalo bi ovde da removeLogoView...
                self.present(alertVC, animated: true)
            case .remove: self.removeLogoView()
                                checkLocationAvailability()
            }
            
//            if webView.estimatedProgress == 1 { // ovo je radilo...
//                self.removeLogoView()
//                checkLocationAvailability()
//            }
            
        }
    }
    */
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

// ova func zna da na osnovu params vremena, i dokle je stigao sa download, vrati da li da se nastavi ili ne
func loadingUrlIsFastEnough(time: Int, timeLimit: Int, progress: Double) -> LogoViewAction {

    //temp off
    return .removeWithAlert
//    guard time <= timeLimit else {
//        print("vreme je isteklo za loading mobile page.....")
//        return .removeWithAlert} // vreme je isteklo prekini download..
//
//    if progress > Constants.Agremo.loadingLimit {
//        print("progres je veci, ukloni webView")
//        return .remove
//    } else {
//        print("progres je manji ali vreme nije isteklo, cekaj jos....")
//        return .wait
//    }
    
}


struct NotificationSubscriber {
 
    static func startToObserveNotifications(onListener vc: UIViewController,
                                                       dict: [NSNotification.Name: Selector]) {
        
        let _ = dict.keys.map {NotificationCenter.default.addObserver(vc,
                                                              selector: dict[$0]!,
                                                              name: $0,
                                                              object: nil)}
        
    }
    
    static func stopToObserveNotifications(onListener vc: UIViewController, names: [NSNotification.Name]) {
        
        let _ = names.map {NotificationCenter.default.removeObserver(vc, name: $0, object: nil)}
        
    }
}



class AgremoWkWebView: WKWebView {
    
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // prati dokle je stigao sa loading...
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            
            print("AgremoWkWebView.estimatedProgress = \(self.estimatedProgress)")
            
            if self.estimatedProgress == 1 { // ovo je radilo...
                print("AgremoWkWebView.observeValue: status finished")
            }
        }
    }
}

