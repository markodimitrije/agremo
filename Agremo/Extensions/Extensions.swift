//
//  Extensions.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 13/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import RMessage

// MARK:- marko writes, other's classes

extension UIApplication {
    static var view: UIView? {
        return UIApplication.shared.keyWindow?.rootViewController?.view
    }
}

extension RMessage {
    struct Agremo {
        static func showCoreLocationWarningMessage() {
            RMessage.showNotification(withTitle: RMessageText.coreLocationUnavailableTitle, subtitle: RMessageText.coreLocationUnavailableMsg, iconImage: #imageLiteral(resourceName: "Agremo_icon_44x44"), type: RMessageType.warning, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "SETTINGS", buttonCallback: {
                RMessage.dismissActiveNotification()
                if let url = URL(string: UIApplicationOpenSettingsURLString) { // ovo je ok ali root
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                
            }, at: RMessagePosition.navBarOverlay,
               canBeDismissedByUser: true)
        }
    }
}

extension FileManager {
    
    static func saveToDisk(data: Data, fileName: String, ext: String) {
        
        let writeUrl = destinationUrl(fileName: fileName, ext: ext)
        //print("writeUrl = \(writeUrl)")
        
        do {
            try data.write(to: writeUrl, options: .atomic)
            print(" data saved !!! all good...")
        } catch {
            print("catch.cant save data")
        }
        
    }
    
    static var docDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func destinationUrl(fileName: String, ext: String) -> URL {
        return docDir.appendingPathComponent(fileName).appendingPathExtension(ext)
    }
}
