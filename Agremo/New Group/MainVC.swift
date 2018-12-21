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
    
    //let sv = UIStackView.init(frame: UIScreen.main.bounds)
    //let sv = UIView.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: UIScreen.main.bounds.width, height: 10)))
    //private let sv = UIStackView.init(frame: CGRect.init(origin: CGPoint.zero,
//                                                         size: CGSize.init(width: UIScreen.main.bounds.width, height: 10)))
    
    @IBOutlet weak var sv: UIStackView!
    @IBOutlet weak var stackHeightCnstr: NSLayoutConstraint!
    
    
    private lazy var downloadsProgressManager = DownloadsProgressManager(stackView: sv, stackHeightCnstr: stackHeightCnstr)
    
    var locationManager: CLLocationManager!
    
    lazy var clUpdater: CoreLocationUpdating = {
        return AgremoCLUpdater(webView: myWebView)
    }()
    
    let observeNotificationsDict: [NSNotification.Name: Selector] = [
        .UIApplicationDidBecomeActive: #selector(MainVC.applicationDidBecomeActive),
        .UIApplicationDidEnterBackground: #selector(MainVC.applicationDidEnterBackground)]
    
    override func viewDidLoad() { super.viewDidLoad()
        
        downloadsProgressManager.myDelegate = self
        
        configureWebView()
        
        configureDownloadsView()
        
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
    
    private func configureDownloadsView() {
        
        if !myWebView.subviews.map({$0.tag}).contains(12) { // samo ako vec nije na screenu, dodaj ga ...
            sv.tag = 12
            sv.axis = .vertical
            sv.layer.zPosition = 100
            sv.distribution = UIStackView.Distribution.fillEqually
            sv.spacing = 8.0
            myWebView.addSubview(sv)
            
            print("configureDownloadsView/dodajem stackView")
        }
        
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
        
        if !isDownloadFileUrl(addr) { // ako nije download link
            decisionHandler(.allow)
            return
        }
        
        if let lastChar = addr.last, lastChar == "/" {
            decisionHandler(.cancel)
            return
        }
        
        print("tap is catched, myUrl is = \(addr)")
        
        if isDownloadFileUrl(addr) {
            
            guard let tempFileName = getTempFilename(addr),
                !downloadsProgressManager.hasActiveSession(withName: tempFileName) else {
                    print("decidePolicyFor.error: nemam temp filename iz url-a \(addr) ili je session alive")
                    decisionHandler(.cancel)
                return
            }
            
            print("PROSAO link !!!", addr)
            
            ServerRequest.downloadAgremoArchiveInBackground(addr: addr, delegate: downloadsProgressManager, filename: tempFileName)
            
        }
        
        decisionHandler(.allow) // uvek dopustas, nije vise blob, da se iscrta na screen....
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print("imam ok odgovor za URL : :: : :: \(navigationResponse.response.url!)")
        
        guard let downloadLinkData = isAgremoResourceDownloadUrl(response: navigationResponse.response), downloadLinkData else {
            decisionHandler(.allow) // decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }
        
        decisionHandler(.cancel)
        
    }
    
}

extension MainVC: UIDocumentInteractionControllerDelegate {
    //MARK: UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
    {
        return self
    }
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
