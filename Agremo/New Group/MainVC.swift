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
        
        print("tap is catched, myUrl is = \(addr)")
        
        if isDownloadFileUrl(addr) {
            
            guard let tempFileName = getTempFilename(addr),
                !downloadsProgressManager.hasActiveSession(withName: tempFileName) else {
                    print("decidePolicyFor.error: nemam temp filename iz url-a \(addr) ili je session alive")
                    decisionHandler(.allow)
                return
            }
            
            //RMessage.Agremo.showFileDownloadMessage()
            
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

class DownloadsProgressManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, FilePreviewResponding {
    
    var activeSessions = [DownloadInfo]()
    var stackView: UIStackView
    var stackHeightCnstr: NSLayoutConstraint
    
    weak var myDelegate: UIDocumentInteractionControllerDelegate?
    
    init(stackView: UIStackView, stackHeightCnstr: NSLayoutConstraint) {
        self.stackView = stackView
        self.stackHeightCnstr = stackHeightCnstr
    }
    
    func sessionStarted(session: URLSession, task: URLSessionDownloadTask) {
        
        //let downloadInfo = DownloadInfo(session: session, location: nil,
        let downloadInfo = DownloadInfo.init(session: session, location: nil, realFilename: nil)
        
        activeSessions.append(downloadInfo)
        
        let frame = CGRect.init(origin: stackView.frame.origin,
                                size: CGSize.init(width: stackView.bounds.width, height: Constants.DownloadView.height))
        
        let progressView = DownloadProgressView.init(frame: frame,
                                                     sessionIdentifier: downloadInfo.sessionName)
        
        progressView.delegate = self
        
        progressView.parentHeightCnstr = stackHeightCnstr
        
        stackView.addArrangedSubview(progressView)

        self.stackHeightCnstr.constant = CGFloat(stackView.subviews.count * Constants.DownloadView.heightWithGap)
        
    }
    
    // MARK:- delegate methods
    
    func preview(sessionIdentifier: String) {
        if let sessionInfo = activeSessions.first(where: { (info) -> Bool in
            info.sessionName == sessionIdentifier
        }) {
            guard let url = sessionInfo.location,
                let filename = sessionInfo.filename else {return}
            
            previewFile(filename: filename, didFinishDownloadingTo: url)
            manageStateWithSession(identifier: sessionIdentifier)
            
        }
        
    }
    
    func hide(sessionIdentifier: String) {
        
        manageStateWithSession(identifier: sessionIdentifier)
        
    }
    
    // omoguci da je OK btn tap dostupan...
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        //manageStateWithSessionIdentifiers(session: session) hard-coded
        
        if let index = activeSessions.firstIndex(where: { info -> Bool in
            return info.sessionName == session.configuration.identifier ?? ""
        }) {
            guard let responseInfo = getDownloadFileInfo(response: downloadTask.response) else {return}
            activeSessions[index] = DownloadInfo.init(session: session, location: location, realFilename: responseInfo.filename)
        }
        
        
        
        // cim je gotovo, momentalno oslobodi iz svoje global koja prati state...
        guard let tempFilename = session.configuration.identifier,
            let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            let responseInfo = getDownloadFileInfo(response: httpResponse) else {
                handleUrlSession(session, downloadTask: downloadTask, totalBytesWritten: nil, totalBytesExpectedToWrite: nil)
                return
        }
        
        FileManager.persistDownloadedFile(tempFilename: tempFilename, at: location, as: responseInfo.filename)
        
        // obezbedi preview
        
        //previewFile(filename: responseInfo.filename, didFinishDownloadingTo: location)
        
    }
    
    private func previewFile(filename: String, didFinishDownloadingTo location: URL) {
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/" + "\(filename)"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            showFileWithPath(path: destinationURLForFile.path)
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                showFileWithPath(path: destinationURLForFile.path)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }
    
    private func showFileWithPath(path: String){
        
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true{
            DispatchQueue.main.async {
                let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
                viewer.delegate = self.myDelegate
                viewer.presentPreview(animated: true)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // handle ikonicom da je error ili pitaj kako...
        
        func errorReceived() {
            print("error is catched for session and task!!")
            handleProgressViewForSessionError(session: session)
            manageStateWithSessionIdentifiers(session: session)
        }
        
        if error != nil {
            
            errorReceived()
        
        } else {
            
            guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode,
                !(200...299).contains(statusCode) else {
                    return
            }
            
            errorReceived() // 404 i slicno....
            
        }
        
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        handleUrlSession(session, downloadTask: downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
    }
    
    
    
    private func handleUrlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, totalBytesWritten: Int64?, totalBytesExpectedToWrite: Int64?) {
        
        let downloadOk = (totalBytesWritten != nil && totalBytesExpectedToWrite != nil)
        
        guard let sessionId = session.configuration.identifier else {
            return
        }
        
        let progress = downloadOk ? Int(100 * Float(totalBytesWritten!) / 5022606) /* hard-coded za Jerry's farm, server treba da posalje Content-Length */ : 2
        
        if let index = activeSessions.firstIndex(where: { (info) -> Bool in
            info.sessionName == sessionId
        }) {
            
            activeSessions[index].progress = progress
            
            var statusDesc = (progress < 2) ? DownloadingInfoText.preparing : DownloadingInfoText.downloading
            
            let filename = getDownloadFileInfo(downloadTask: downloadTask)?.filename
            
            if progress == 100 { statusDesc = DownloadingInfoText.finished }
            
            let file = downloadOk ? filename : "server error, try again later"
            
            let info = ProgressViewInfo.init(session: session, statusDesc: statusDesc, percent: progress, filename: file, dismissBtnTxt: DownloadingInfoText.hide, previewFileBtnTxt: DownloadingInfoText.preview)

            updateProgressView(forSession: session, withInfo: info, hasError: !downloadOk)
            
        }
    }
    
    private func handleProgressViewForSessionError(session: URLSession) {
        
        let info = ProgressViewInfo.init(session: session, statusDesc: "server error, try again later", percent: 1, filename: "", dismissBtnTxt: DownloadingInfoText.hide, previewFileBtnTxt: DownloadingInfoText.preview)

        updateProgressView(forSession: session, withInfo: info, hasError: true)
        
    }
    
    private func updateProgressView(forSession session: URLSession, withInfo info: ProgressViewInfo, hasError: Bool) {
        
        guard let sessionId = session.configuration.identifier else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else {return}
            
            let progressViews = sSelf.stackView.arrangedSubviews.filter {$0 is DownloadProgressView}.compactMap {$0 as? DownloadProgressView}
            let viewToUpdate = progressViews.first(where: {$0.sessionIdentifier == sessionId})
            viewToUpdate?.update(info: info)
            
            if hasError {
                delay(1.0, closure: {
                    guard let sSelf = self else {return}
                    guard let superview = viewToUpdate?.superview else {return}
                    sSelf.stackHeightCnstr.constant = superview.frame.height - CGFloat(Constants.DownloadView.heightWithGap)
                    viewToUpdate?.removeFromSuperview()
                })
            }
            
        }
        
    }
    
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
            guard let handler = appDelegate.backgroundCompletionHandler else { return }
            handler() // izvrsi svoj handler, njega si save ranije, (da izvrsi save downloaded data na disk - mislim da ne tu...)
        }
    }
    
    func hasActiveSession(withName name: String) -> Bool {
        return activeSessions.map {$0.sessionName}.contains(name)
    }
    
    private func manageStateWithSessionIdentifiers(session: URLSession) {

        if let index = activeSessions.firstIndex(where: { (info) -> Bool in
            info.sessionName == (session.configuration.identifier ?? "")
        }) {
            print("\(activeSessions[index].sessionName) je finished, prikazi OK btn")
            
            self.activeSessions.remove(at: index)
            
        }
    }
    
    private func manageStateWithSession(identifier: String) {
        
        if let index = activeSessions.firstIndex(where: { (info) -> Bool in
            info.sessionName == identifier
        }) {
            print("\(activeSessions[index].sessionName) je finished, prikazi OK btn")
            
            self.activeSessions.remove(at: index)
            
        }
    }
    
}

struct DownloadInfo {
    var sessionName: String = ""
    var progress: Int = 0
    
    var filename: String?
    var location: URL?
    
    init(session: URLSession) {
        self.sessionName = session.configuration.identifier ?? ""
    }
    
    init(session: URLSession, location: URL?, realFilename: String?) {
        self.sessionName = session.configuration.identifier ?? ""
        self.location = location
        self.filename = realFilename
    }
}

