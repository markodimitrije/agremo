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
    
    override func viewDidLoad() { super.viewDidLoad()
        
        let launchSB = UIStoryboard.init(name: "LaunchScreen", bundle: nil)
        if let mainVC = launchSB.instantiateViewController(withIdentifier: "LaunchScreenVC") as? UIViewController {
            print("imam launch preko SB-a!")
        }
        
        configureDummyBackBtnAndAddItToViewHierarchy()
        
        requestCoreLocationAuth()
        
        checkConnectivityWithAgremoBackend()
        
        webView.load(URLRequest.agremo)
        
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
        //showLogoView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        checkConnectivityWithAgremoBackend()
        if CLLocationManager.authorizationStatus() != .notDetermined {
            checkCoreLocationAvailability()
        }
    }
    
    @objc func applicationDidEnterBackground() {
        showLogoView()
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
                    let logoView = UIApplication.view?.subviews.first(where: {$0.tag==12})
                    logoView?.removeFromSuperview()
                    self?.logoRemovedFromScreen()
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
    
    private func checkCoreLocationAvailability() {
        if CLLocationManager.authorizationStatus() == .denied {
//            RMessage.showNotification(withTitle: RMessageText.coreLocationUnavailableTitle, subtitle: RMessageText.coreLocationUnavailableMsg, iconImage: #imageLiteral(resourceName: "agrem"), type: RMessageType.warning, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "!", buttonCallback: {}, at: RMessagePosition.navBarOverlay, canBeDismissedByUser: true)
            
            RMessage.showNotification(withTitle: RMessageText.coreLocationUnavailableTitle, subtitle: RMessageText.coreLocationUnavailableMsg, iconImage: #imageLiteral(resourceName: "agrem"), type: RMessageType.warning, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "SETTINGS", buttonCallback: {
                RMessage.dismissActiveNotification()
                if let url = URL(string: UIApplicationOpenSettingsURLString) { // ovo je ok ali root
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                
            }, at: RMessagePosition.navBarOverlay,
               canBeDismissedByUser: true)
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func logoRemovedFromScreen() {
        //checkCoreLocationAvailability() // proveri da li mu je ukljucen GPS
    }
    
    // MARK:- poziva sistem jer si delegate za CoreLocation
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0] as CLLocation
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
}

extension URLRequest {
    static var agremo: URLRequest {
        let url = URL.init(string: "https://app.agremo.com/mobile/#")!
        return URLRequest.init(url: url)
    }
}

