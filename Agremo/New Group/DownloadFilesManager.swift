//
//  DownloadFilesManager.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/12/2018.
//  Copyright © 2018 Agremo. All rights reserved.
//

import UIKit; import CoreLocation; import RMessage; import WebKit

// MARK: Protocol + implementacija od strane MainVC

protocol AgremoWkWebViewLoadingDelegate: class {
    func webView(_ webView: WKWebView, didFinishLoading success: Bool)
}

class DownloadsProgressManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, FilePreviewResponding {
    
    var timer: Timer!
    
    var activeSessions = [DownloadInfo]()
    var stackView: UIStackView
    var stackHeightCnstr: NSLayoutConstraint
    
    weak var myDelegate: UIDocumentInteractionControllerDelegate?
    
    init(stackView: UIStackView, stackHeightCnstr: NSLayoutConstraint) {
        self.stackView = stackView
        self.stackHeightCnstr = stackHeightCnstr
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval.init(1),
                                   target: self,
                                   selector: #selector(DownloadsProgressManager.checkIdleDownloads),
                                   userInfo: nil,
                                   repeats: true)
    }
    
    @objc func checkIdleDownloads() { //print("timer counts...")
        
        for info in activeSessions {
            if Date.init() > info.timestamp.addingTimeInterval(Constants.Download.idlePeriod) {
            //if Date.init() > info.timestamp.addingTimeInterval(10) { testing
                if let progressView = (stackView.subviews as! [DownloadProgressView]).first(where: { downloadView -> Bool in
                    return downloadView.sessionIdentifier == info.sessionName
                }) {
                    if info.progress <= Constants.Download.prepareForDownloadPercent {
//                    if info.progress <= 100 { testing
                        progressView.downloadFailed()
                        
                        manageStateWithSession(identifier: info.sessionName)// activeSessions.remove(at: index)
                        
                        RMessage.Agremo.showDownloadFileInternetConnectionError()
                    }
                }
            }
        }
    }
    
    func sessionStarted(session: URLSession, task: URLSessionDownloadTask) {
        
        print("session started! = \(session.configuration.identifier!)")
        
        //let downloadInfo = DownloadInfo(session: session, location: nil,
        let downloadInfo = DownloadInfo.init(session: session, location: nil, realFilename: nil)
        
        activeSessions.append(downloadInfo)
        
        let frame = CGRect.init(origin: stackView.frame.origin,
                                size: CGSize.init(width: stackView.bounds.width, height: Constants.DownloadView.height))
        
        let progressView = DownloadProgressView.init(frame: frame,
                                                     sessionIdentifier: downloadInfo.sessionName)
        
        progressView.delegate = self
        
        progressView.swipeDelegate = myDelegate as? StackScrolling
        
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
    
    func hide(sessionIdentifier: String, isFinished: Bool) {
        
        if !isFinished && (activeSessions.map {$0.sessionName}).contains(sessionIdentifier) { // ispremestao sam ovo, necitko je ....
            RMessage.Agremo.showFileWillBeAvailableInFilesAppMessage(success: "")
        }
        
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
                print("O-O not good, no fileinfo......)")
                return
        }
        
        FileManager.persistDownloadedFile(tempFilename: tempFilename, at: location, as: responseInfo.filename)
        
        print("DownloadFilesManager.didFinishDownloadingTo.responseInfo.filename = \(responseInfo.filename)")
        
        handleUrlSession(session, downloadTask: downloadTask, totalBytesWritten: 100, totalBytesExpectedToWrite: 100) // jednostavno je finished
        
        session.finishTasksAndInvalidate() // JAKO VAZNO !
        
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
        
        print("my path = \(path)")
        
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true{
            DispatchQueue.main.async {
                let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
                viewer.delegate = self.myDelegate
                viewer.presentPreview(animated: true)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) { // handle ikonicom da je error ili pitaj kako...
        print("didCompleteWithError is called, error = \(error)")
        if let error = error {
            self.handleServerOrClientNetworkErrors(session: session, task: task, error: error)
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError is called")
        handleServerOrClientNetworkErrors(session: session, task: nil, error: error)
    }
    
    private func handleServerOrClientNetworkErrors(session: URLSession, task: URLSessionTask?, error: Error?) {
        
        func errorReceived(_ error: Error?) {
            print("error is catched for session and task!!, error = \(error?.localizedDescription ?? "unknown error")")
            handleProgressViewForSessionError(session: session)
            manageStateWithSessionIdentifiers(session: session)
        }
        
        if error != nil {
            
            errorReceived(error!)
            
        } else {
            
            guard let statusCode = (task?.response as? HTTPURLResponse)?.statusCode,
                !(200...299).contains(statusCode) else {
                    return
            }
            
            print("didCompleteWithError.error.statusCode = \(statusCode), timestamp = \(Date.init(timeIntervalSinceNow: 0))")
            
            errorReceived(nil) // 404 i slicno....
            
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        handleUrlSession(session, downloadTask: downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        
    }
    
    
    
    private func handleUrlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, totalBytesWritten: Int64?, totalBytesExpectedToWrite: Int64?) {
        
        let downloadOk = (totalBytesWritten != nil && totalBytesExpectedToWrite != nil)
        
        guard let sessionId = session.configuration.identifier else { return }
        
        let progress = downloadOk ? Int(100 * Float(totalBytesWritten!) / Float(totalBytesExpectedToWrite!)) : 2 // 2 je 2 %
        
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else {return}
        
            if let index = sSelf.activeSessions.firstIndex(where: { (info) -> Bool in
                info.sessionName == sessionId
            }) {
                
                sSelf.activeSessions[index].progress = progress
                
                var statusDesc = (progress <= Constants.Download.prepareForDownloadPercent) ? DownloadingInfoText.preparing : DownloadingInfoText.downloading
                
                let filename = getDownloadFileInfo(downloadTask: downloadTask)?.filename
                
                if progress == 100 { statusDesc = DownloadingInfoText.finished }
                
                let file = downloadOk ? filename : RMessageText.serverErrorTryAgain
                
                let info = ProgressViewInfo.init(session: session, statusDesc: statusDesc, percent: progress, filename: file, dismissBtnTxt: DownloadingInfoText.hide, previewFileBtnTxt: DownloadingInfoText.preview)
                
                sSelf.updateProgressView(forSession: session, withInfo: info, hasError: !downloadOk)
            }
        }
    }
    
    private func handleProgressViewForSessionError(session: URLSession) {
        
        let info = ProgressViewInfo.init(session: session, statusDesc: RMessageText.serverErrorTryAgain, percent: 1, filename: "", dismissBtnTxt: DownloadingInfoText.hide, previewFileBtnTxt: DownloadingInfoText.preview)
        
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
            print("\(activeSessions[index].sessionName) je finished, ukloni je sa activeSessions, i dozvoli preview")
            
            self.activeSessions.remove(at: index)
            
        }
    }
    
    private func manageStateWithSession(identifier: String) {
        
        if let index = activeSessions.firstIndex(where: { (info) -> Bool in
            info.sessionName == identifier
        }) {
//            print("\(activeSessions[index].sessionName) je finished, prikazi OK btn")
            
            self.activeSessions.remove(at: index)
            
        }
    }
    
}

struct DownloadInfo {
    var sessionName: String = ""
    var progress: Int = 0
    var timestamp = Date.init()
    
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

extension MainVC: StackScrolling {
    @objc func onProgressViewScroll(_ direction: UISwipeGestureRecognizerDirection) { //UISwipeGestureRecognizerDirection treba mi kao param
        
        var newOriginX: CGFloat = self.sv.frame.origin.x
        
        var actualOr: CGPoint {
            return self.sv.frame.origin // moze biti levo = middle = desno
        }
        
        let bounds = self.sv.bounds // const
        
        let shiftedX = bounds.width * 0.95
        
        var stackIsLeft: Bool { return actualOr.x < -bounds.width/2 }
        var stackIsRight: Bool { return actualOr.x > bounds.width/2 }
        
        switch direction {
        
        case .left:
            
            if stackIsLeft { return } // ako si vec left, ignore...
            
            newOriginX = stackIsRight ? 0.0 : -shiftedX
            
        case .right:
            
            if stackIsRight { return } // ako si vec desno, ignore...
            
            newOriginX = stackIsLeft ? 0.0 : shiftedX
            
        default: break
        }
        
        let newOr = CGPoint.init(x: newOriginX, y: actualOr.y)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.sv.frame = CGRect.init(origin: newOr, size: bounds.size)
        }, completion: nil)
        
    }
}

