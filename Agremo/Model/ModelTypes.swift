//
//  ModelTypes.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

enum AlertType {
    case pingAgremo
    case appLoadingToSlow
    case cantOpenUrlScheme
}

struct AlertInfo {
    
    static let ok = NSLocalizedString("Strings.Alert.ok", comment: "")
    
    struct PingAgremoApp {
        static let title = NSLocalizedString("Strings.PingAgremo.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.PingAgremo.Alert.message", comment: "")
    }
    struct appLoadingToSlow {
        static let title = NSLocalizedString("Strings.AppLoadingToSlow.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.AppLoadingToSlow.Alert.message", comment: "")
    }
    struct CantOpenUrlScheme {
        static let title = NSLocalizedString("Strings.CantOpenUrlScheme.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.CantOpenUrlScheme.Alert.message", comment: "")
    }
}

struct RMessageText {
    static let coreLocationUnavailableTitle = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.title", comment: "")
    static let coreLocationUnavailableMsg = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.msg", comment: "")
    static let fileDownloadTitle = NSLocalizedString("Strings.RMessageText.FileDownload.title", comment: "")
    static let fileDownloadMsg = NSLocalizedString("Strings.RMessageText.FileDownload.msg", comment: "")
    
    static let fileDownloadMsgStatusOk = NSLocalizedString("Strings.RMessageText.FileDownloadStatus.OK", comment: "")
    static let fileDownloadMsgStatusFailed = NSLocalizedString("Strings.RMessageText.FileDownloadStatus.Failed", comment: "")
    
}

extension URLRequest {
    
    static var agremo: URLRequest {
        let url = URL.init(string: "https://app.agremo.com/mobile/#")!
        //return URLRequest.init(url: url)
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobileLoadContent)
    }
    static var agremoTest: URLRequest {
        let url = URL.init(string: "https://daliznas.com/ios_test/index.html")!
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobileLoadContent)
    }
    
    
    // hard-coded, treba kasnije da remove....
    
    static func getRequest(addr: String, timeout: TimeInterval) -> URLRequest? {
        
        guard let url = URL.init(string: addr) else {return nil}
        
        return URLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        
    }
    
}

enum TimeOut {
    //static let agremoMobile = TimeInterval.init(0.05)
    static let agremoMobileLoadContent = TimeInterval.init(10.0) // bilo je 7.0
    static let downloadArchive = TimeInterval.init(60.0) // bilo je 10.0
}

struct Constants {
    struct AgremoWebView {
        static let estimatedProgressLimit: Double = 0.9 // ako je za timeout ucitao manje od 75% daj mu alert da je pure
    }
    struct Location {
        static let sugnificantDistToUpdateJSLocationFunc = 1.0 // ovo je 1 metar...
        //static let sugnificantDistToUpdateJSLocationFunc = 5.0 // ovo je 5 metar... hard-coded to test
    }
    struct DownloadView {
        static let height = CGFloat(80)
        static let gap = CGFloat(8)
        static var heightWithGap: Int {
            return Int(height + gap)
        }
    }
}
