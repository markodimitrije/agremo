//
//  ModelTypes.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation

enum AlertType {
    case quitAgremoApp
    case pingAgremo
    case appLoadingToSlow
}

struct AlertInfo {
    
    static let ok = NSLocalizedString("Strings.Alert.ok", comment: "")
    
    struct QuitAgremoApp {
        static let title = NSLocalizedString("Strings.QuitApp.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.QuitApp.Alert.message", comment: "")
        static let no = NSLocalizedString("Strings.QuitApp.Alert.no", comment: "")
        static let yes = NSLocalizedString("Strings.QuitApp.Alert.yes", comment: "")
    }
    struct PingAgremoApp {
        static let title = NSLocalizedString("Strings.PingAgremo.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.PingAgremo.Alert.message", comment: "")
    }
    struct appLoadingToSlow {
        static let title = NSLocalizedString("Strings.AppLoadingToSlow.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.AppLoadingToSlow.Alert.message", comment: "")
    }
}

struct RMessageText {
    static let coreLocationUnavailableTitle = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.title", comment: "")
    static let coreLocationUnavailableMsg = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.msg", comment: "")
}

extension URLRequest {
    static var agremo: URLRequest {
        let url = URL.init(string: "https://app.agremo.com/mobile/#")!
        //return URLRequest.init(url: url)
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobile)
    }
    static var agremoTest: URLRequest {
        let url = URL.init(string: "https://daliznas.com/ios_test")!
        return URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeOut.agremoMobile)
    }
}

enum TimeOut {
    //static let agremoMobile = TimeInterval.init(0.05)
    static let agremoMobile = TimeInterval.init(7.0)
}

struct Constants {
    struct Agremo {
        static let loadingLimit: Double = 0.75 // ako je za timeout ucitao manje od 75% daj mu alert da je pure
    }
}

enum LogoViewAction {
    case wait
    case remove
    case removeWithAlert
}
