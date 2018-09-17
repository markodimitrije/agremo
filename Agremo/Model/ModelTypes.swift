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
}

struct RMessageText {
    static let coreLocationUnavailableTitle = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.title", comment: "")
    static let coreLocationUnavailableMsg = NSLocalizedString("Strings.RMessageText.CoreLocationUnavailable.msg", comment: "")
}
