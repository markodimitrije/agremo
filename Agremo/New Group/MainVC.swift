//
//  MainVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit; import CoreLocation; import RMessage; import WebKit

class MainVC: UIViewController, CLLocationManagerDelegate, AgremoWkWebViewLoadingDelegate {
    
    var myWebView: AgremoWkWebView! // WKWebView
    
    var locationManager: CLLocationManager!
    
    lazy var clUpdater: CoreLocationUpdating = {
        return AgremoCLUpdater(webView: myWebView)
    }()
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        configureWebView()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        showLogoView()
        
    }
    
    private func configureWebView() {
    
        let webConfiguration = WKWebViewConfiguration()
        
        myWebView = AgremoWkWebView.init(frame: self.view.bounds, configuration: webConfiguration)
        
        self.view.addSubview(myWebView)
        
        myWebView.uiDelegate = self; myWebView.navigationDelegate = self; myWebView.loadingDelegate = self
        
        myWebView.load(URLRequest.agremo)
        
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
    
    fileprivate func appReceivedFileContent(data: Data, withFilename filename: String) {
        
        DispatchQueue.main.async {
            
            FileManager.saveToDisk(data: data,
                                   inDirectory: FileManager.applicationSupportDir,
                                   filenameWithExtension: filename)
            
        }
        
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
        
//        print("user latitude = \(userLocation.coordinate.latitude)")
//        print("user longitude = \(userLocation.coordinate.longitude)")
        
        // za sada zovem odavde ali u stvari treba dodati javaScriptLocation objektu koji ce da embed poslednju lokaciju, a onda sledecu uporedi sa prethodnom, pa ako je diff >=1m, onda stvarno zovi JS func
        
        clUpdater.locationUpdated(location: userLocation)
        
    }
    
}


extension MainVC: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let addr = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
        
        print("tap is catched, myUrl is = \(addr)")
        
        if isDownloadFileUrl(addr) {
            
            guard let tempFileName = getTempFilename(addr),
                !liveDownloadSessionsIdentifiers.contains(tempFileName) else { // ako nisi u global state monitor
                    print("decidePolicyFor.error: nemam temp filename iz url-a \(addr) ili je session alive")
                    decisionHandler(.allow)
                return
            }
            
            RMessage.Agremo.showFileDownloadMessage()
            
            liveDownloadSessionsIdentifiers.append(tempFileName)
            
            ServerRequest.downloadAgremoArchiveInBackground(addr: addr, delegate: self, filename: tempFileName)
            
        }
        
        decisionHandler(.allow) // uvek dopustas, nije vise blob, da se iscrta na screen....
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print("URL IS : :: : :: \(navigationResponse.response.url!)")
        
        guard let downloadLinkData = isAgremoResourceDownloadUrl(response: navigationResponse.response), downloadLinkData else {
            decisionHandler(.allow) // decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }
        
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


// bg download
extension MainVC: URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
            guard let handler = appDelegate.backgroundCompletionHandler else { return }
            handler() // izvrsi svoj handler, njega si save ranije, da izvrsi save downloaded data na disk
        }
    }
    
    
    
    // ova func se moze izvrsiti pre ili nakon sto se dobije "filename" u decidePolicyFor response !
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        manageStateWithSessionIdentifiers(session: session)
        
        // cim je gotovo, momentalno oslobodi iz svoje global koja prati state...
        guard let tempFilename = session.configuration.identifier else { return }
        
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else { print ("server error")
                return
        }
        
        guard let responseInfo = getDownloadFileInfo(response: httpResponse) else {return}

        FileManager.persistDownloadedFile(tempFilename: tempFilename, at: location, as: responseInfo.filename)
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        manageStateWithSessionIdentifiers(session: session)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        //let progress = abs(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        let progress = Float(totalBytesWritten) / 5022606 // hard-coded za Jerry's farm, server treba da posalje Content-Length
        
        print("trenutno skidam =  \(progress * 100)")
        
//        DispatchQueue.main.async {
//            //self.progressDownloadIndicator.progress = progress
            //print("nadji ref na view i prikazi....")
//        }
        
        
        
        
    }
    
    func calculateProgress(session : URLSession, completionHandler : @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let bytesReceived = downloads.map{ $0.countOfBytesReceived }.reduce(0, +)
            let bytesExpectedToReceive = downloads.map{ $0.countOfBytesExpectedToReceive }.reduce(0, +)
            let progress = bytesExpectedToReceive > 0 ? Float(bytesReceived) / Float(bytesExpectedToReceive) : 0.0
            completionHandler(progress)
        }
    }
    
    private func manageStateWithSessionIdentifiers(session: URLSession) {
        guard let tempFilename = session.configuration.identifier else { return }
        if let index = liveDownloadSessionsIdentifiers.firstIndex(of: tempFilename) { // handle state, mozes opet isti file da skidas...
            liveDownloadSessionsIdentifiers.remove(at: index)
        }
    }
    
}
