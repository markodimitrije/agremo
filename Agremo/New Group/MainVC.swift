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
    
//    @IBAction func tempCallScriptBtnTapped(_ sender: UIButton) {
////        executeGetTokenJavaScript()\
//        executeLoadMyCurrentLocationJavaScript()
//    }
//
//    @IBAction func tempCallDownloadZipBtnTapped(_ sender: UIButton) {
//
//        //userWantsToDownloadZip(atUrl: URL, filename: "")
//
//    }
    
    fileprivate func userWantsToDownloadZip(atUrl url: URL, filename: String) {
        
        let addr = url.absoluteString
        
        ServerRequest.downloadAgremoZip(addr: addr) { (data) in guard let data = data else {return}
            
            //FileManager.saveToDiskInDocDir(data: data, filenameWithExtension: filename)
            
            FileManager.saveToDisk(data: data,
                                   inDirectory: FileManager.applicationSupportDir,
                                   filenameWithExtension: filename)
        }
    }
    
    @IBOutlet weak var myWebView: AgremoWkWebView! // WKWebView
    
    var locationManager: CLLocationManager!
    
    lazy var clUpdater: CoreLocationUpdating = {
        return AgremoCLUpdater(webView: myWebView)
    }()
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        configureDummyBackBtnAndAddItToViewHierarchy()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        myWebView.uiDelegate = self; myWebView.navigationDelegate = self; myWebView.loadingDelegate = self
        
        showLogoView()
        
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
        
        // za sada zovem odavde ali u stvari treba dodati javaScriptLocation objektu koji ce da embed poslednju lokaciju, a onda sledecu uporedi sa prethodnom, pa ako je diff >=1m, onda stvarno zovi JS func
        
//        loadMyCurrentLocation(userLocation.coordinate.latitude,
//                              userLocation.coordinate.longitude)
        
//        executeLoadMyCurrentLocationJavaScript(userLocation: userLocation)
        
//        executeGetTokenJavaScript()
        clUpdater.locationUpdated(location: userLocation)
        

    }
    
    //webView.evaluateJavaScript("document.getElementById('someElement').innerText")
    
    //theWebView!.evaluateJavaScript("storeAndShow( \(aCount + 1) )",
    //completionHandler: nil)
    
    private func executeLoadMyCurrentLocationJavaScript(userLocation: CLLocation) {
        let lat = userLocation.coordinate.latitude
        let long = userLocation.coordinate.longitude
        let _ = myWebView.evaluateJavaScript("loadMyCurrentLocation(\(lat), \(long));") { (data, err) in // trebas params!!
            if err == nil {
                print("executeLoadMyCurrentLocationJavaScript.all good...")
            } else {
                print("loadMyCurrentLocation.err = \(err!.localizedDescription)")
            }
        }
        // koristi ovaj  evaluateJavaScript(_:completionHandler:)
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
    
    private func executeLoadMyCurrentLocationJavaScript() {
        let lat: Float = 7.93
        let lon: Float = 6.25

        
        //"setIOSNativeAppLocation(\(lat), \(lon));"
        //let _ = webView.evaluateJavaScript("loadMyCurrentLocation(\(lat), \(long));") { (data, err) in
        //let _ = webView.evaluateJavaScript("loadMyCurrentLocation('7.93,67.25')") { (data, err) in
        //let _ = webView.evaluateJavaScript("callExampleRandom()") { (data, err) in OVO RADI !!!
        let _ = myWebView.evaluateJavaScript("loadMyCurrentLocation(\(lat), \(lon));") { (data, err) in
            
        
        //let _ = webView.evaluateJavaScript("loadMyCurrentLocation('\(lat)', '\(long)');") { (data, err) in // trebas params!!
            if err == nil {
                print("executeLoadMyCurrentLocationJavaScript.all good...")
            } else {
                print("loadMyCurrentLocation.err = \(err!.localizedDescription)")
            }
        }
        
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
    
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStart provisional...")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) { print("decidePolicyFor action...")
        
        // da li se zavrsavas na .zip ?
            
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        print("decidePolicyFor.navigationAction.address = \(url.absoluteString)")
        
        let policy: WKNavigationActionPolicy = (url.pathExtension != "zip") ? .allow : .cancel
        
        if policy == .cancel {
            
            userWantsToDownloadZip(atUrl: url, filename: url.lastPathComponent)
            
        }
        
        decisionHandler(policy)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("decidePolicyFor response...")
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    /*
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail navigation with error...")
    }
    
    func webView(_ webView: WKWebView, didFinishLoading success: Bool) {
        print("didFinishLoading...")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation...")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("webViewWebContentProcessDidTerminate...")
    }
    
    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        print("pick action")
        return nil
    }
 */
    
    /*
    
    /// Handle javascript:prompt(...)
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
//        ...
//            alertController.addTextFieldWithConfigurationHandler { (textField) in
//                textField.text = defaultText
//        }
//
//        let okAction = UIAlertAction(title: Okay, style: .Default) { action in
//            let textField = alertController.textFields![0] as UITextField
//            completionHandler(textField.text)
//        }
//
//        let cancelAction = UIAlertAction(title: Cancel, style: .Cancel) { _ in
//        completionHandler(nil)
//        }
//        ...
        
        completionHandler("abc")
        print("runJavaScriptTextInputPanelWithPrompt")
    }
    
    /// Handle javascript:alert(...)
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        print("runJavaScriptAlertPanelWithMessage")
        
        //        ...
        //        let okAction = UIAlertAction(title: Okay, style: .Default) { _ in
        //        completionHandler()
        //        }
        //        ...
        
        completionHandler()
    }
    
    
    /// Handle javascript:confirm(...)
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        //        ...
        //        let okAction = UIAlertAction(title: Okay, style: .Default) { _ in
        //            completionHandler(true)
        //        }
        //
        //        let cancelAction = UIAlertAction(title: Cancel, style: .Cancel) { _ in
        //        completionHandler(false)
        //        }
        //        ...
        
        completionHandler(true)
        print("runJavaScriptConfirmPanelWithMessage")
    }
    
    */
    
    
 
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
        
        let _ = webView.evaluateJavaScript("loadMyCurrentLocation(\(lat), \(long));") { (data, err) in
            
            if err == nil {
                print("executeLoadMyCurrentLocationJavaScript.all good...")
            } else {
                print("loadMyCurrentLocation.err = \(err!.localizedDescription)")
            }
        }
        
        
    }
    
}


