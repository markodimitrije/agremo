//
//  MainVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit; import CoreLocation; import RMessage; import WebKit

let token = "9a2b4b9f4e82c1d2043909ff2f08f56f8ac2cc11"

class MainVC: UIViewController, CLLocationManagerDelegate, AgremoWkWebViewLoadingDelegate {
    
    //@IBOutlet weak var holderForWebView: UIView!
    
    var myWebView: AgremoWkWebView! // WKWebView
    
    var locationManager: CLLocationManager!
    
    lazy var clUpdater: CoreLocationUpdating = {
        return AgremoCLUpdater(webView: myWebView)
    }()
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        //configureDummyBackBtnAndAddItToViewHierarchy() remove - delete
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
//        myWebView.uiDelegate = self; myWebView.navigationDelegate = self; myWebView.loadingDelegate = self
        
        showLogoView()
        
        configureWebView()
        
//        myWebView.load(URLRequest.agremo)
//        myWebView.load(URLRequest.agremoTest)
        
    }
    
    private func configureWebView() {
     
        let webConfiguration = WKWebViewConfiguration()
        
        myWebView = AgremoWkWebView.init(frame: self.view.bounds, configuration: webConfiguration)
        
        self.view.addSubview(myWebView)
        
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        myWebView.loadingDelegate = self
        
        myWebView.load(URLRequest.agremo)
//        myWebView.load(URLRequest.agremoTest)
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
            // zove je moj observer, nesto sam menjao ... mozes da je remove odande...
    }
    
    
    fileprivate func userWantsToDownloadZip(atUrl url: URL, filename: String) {
        
        let addr = url.absoluteString
        
        ServerRequest.downloadAgremoZip(addr: addr) { (data) in guard let data = data else {return}
            
            //FileManager.saveToDiskInDocDir(data: data, filenameWithExtension: filename)
            
            FileManager.saveToDisk(data: data,
                                   inDirectory: FileManager.applicationSupportDir,
                                   filenameWithExtension: filename)
        }
    }
    
    fileprivate func appReceivedFileContent(data: Data, withFilename filename: String) {
        
        FileManager.saveToDisk(data: data,
                               inDirectory: FileManager.applicationSupportDir,
                               filenameWithExtension: filename)
        
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
    
    /*
    
    private func showLogoView() {
        
        guard let windowView = UIApplication.viewIfUsingNavVC else {
            return
        }
        
        if let _ = windowView.subviews.first(where: {$0.tag==12}) {
            return // vec ga prikazujes, izadji...
        }
        
        let agremoLogoView = LogoView.init(frame: self.view.bounds); agremoLogoView.tag = 12
        
        windowView.addSubview(agremoLogoView)
    }
    
    fileprivate func removeLogoView() {
        let logoView = UIApplication.viewIfUsingNavVC?.subviews.first(where: {$0.tag==12})
        logoView?.removeFromSuperview()
    }
    
    */
    
    private func showLogoView() {
        
        if let _ = self.view.subviews.first(where: {$0.tag==12}) {
            return // vec ga prikazujes, izadji...
        }
        
        let agremoLogoView = LogoView.init(frame: self.view.bounds); agremoLogoView.tag = 12
        
        self.view.addSubview(agremoLogoView)
    }
    
    fileprivate func removeLogoView() {
        let logoView = self.view.subviews.first(where: {$0.tag==12})
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
        
        // za sada zovem odavde ali u stvari treba dodati javaScriptLocation objektu koji ce da embed poslednju lokaciju, a onda sledecu uporedi sa prethodnom, pa ako je diff >=1m, onda stvarno zovi JS func
        
        clUpdater.locationUpdated(location: userLocation)
        
    }
    
    private func executeGetTokenJavaScript() {
        
        let _ = myWebView.evaluateJavaScript("getToken()") { (data, err) in // trebas params!!
            if err == nil {
                print("executeGetToken.all good...")
            } else {
                print("executeGetToken.err = \(err!.localizedDescription)")
            }
        }
        // koristi ovaj  evaluateJavaScript(_:completionHandler:)
    }
    
}


extension MainVC: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("decidePolicyFor response...")
        //decisionHandler(WKNavigationResponsePolicy.allow)
        
        print("URL IS : :: : :: \(navigationResponse.response.url!)")
        
        guard let downloadLinkData = isAgremoResourceDownloadUrl(response: navigationResponse.response) else {
            decisionHandler(.allow) // decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }
        
        // ako si ovde, onda jeste download link:
        
        appReceivedFileContent(data: downloadLinkData.data, withFilename: downloadLinkData.filename)
        
        print("save data as file to filename = \(downloadLinkData.1)")
        decisionHandler(.cancel)
        
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
