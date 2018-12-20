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
    static let fileWillBeAvailableMsg = NSLocalizedString("Strings.DownloadingView.FileWillBeAvailableInFilesApp", comment: "")
    static let serverErrorTryAgain = NSLocalizedString("Strings.DownloadingView.ServerErrorTryAgain", comment: "")
}

struct DownloadingInfoText {
    static let preparing = NSLocalizedString("Strings.DownloadingView.FileStatus.preparing", comment: "")
    static let downloading = NSLocalizedString("Strings.DownloadingView.FileStatus.downloading", comment: "")
    static let finished = NSLocalizedString("Strings.DownloadingView.FileStatus.finished", comment: "")
    static let hide = NSLocalizedString("Strings.DownloadingView.FileStatus.hide", comment: "")
    static let preview = NSLocalizedString("Strings.DownloadingView.FileStatus.preview", comment: "")
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
    //static let downloadArchive = TimeInterval.init(60.0) // bilo je 10.0
    //static let downloadArchive = TimeInterval.init(5.0) // bilo je 10.0
    static let downloadArchive = TimeInterval.init(10.0) // bilo je 10.0
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
    struct Colors {
        static let progressBar = UIColor.init(red: 247/255, green: 147/255, blue: 29/255, alpha: 1.0)
    }
    
    
//    struct Colors {
//        struct DownloadProgress {
//            static let backgroundView = 0x003a4c
//            static let progressBarBg = 0xffffff
//            static let progressBarLine = 0xf7941d
//            static let progressBarText = 0xf7941d
//            static let btnPreviewText = 0xffffff
//            static let btnHideText = 0xffffff
//            static let btnPreviewBg = 0x00b259
//            static let btnHideBg = 0xef495f
//        }
//    }
}



//extension UIColor {
//    convenience init(red: Int, green: Int, blue: Int) {
//        assert(red >= 0 && red <= 255, "Invalid red component")
//        assert(green >= 0 && green <= 255, "Invalid green component")
//        assert(blue >= 0 && blue <= 255, "Invalid blue component")
//        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
//    }
//
//    convenience init(netHex:Int) {
//        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
//    }
//}

