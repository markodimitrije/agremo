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
}

struct AlertInfo {
    struct QuitAgremoApp {
        static let title = NSLocalizedString("Strings.QuitApp.Alert.title", comment: "")
        static let message = NSLocalizedString("Strings.QuitApp.Alert.message", comment: "")
        static let no = NSLocalizedString("Strings.QuitApp.Alert.no", comment: "")
        static let yes = NSLocalizedString("Strings.QuitApp.Alert.yes", comment: "")
    }
}
