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
    static var viewIfUsingNavVC: UIView? {
        return UIApplication.shared.keyWindow?.rootViewController?.view
    }
}

extension RMessage {
    struct Agremo {
        static func showCoreLocationWarningMessage() {
            RMessage.showNotification(withTitle: RMessageText.coreLocationUnavailableTitle, subtitle: RMessageText.coreLocationUnavailableMsg, iconImage: #imageLiteral(resourceName: "Agremo_icon_44x44"), type: RMessageType.warning, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "SETTINGS", buttonCallback: {
                RMessage.dismissActiveNotification()
                if let url = URL(string: UIApplicationOpenSettingsURLString), // ovo je ok ali root
                    UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }, at: RMessagePosition.navBarOverlay,
               canBeDismissedByUser: true)
        }
        static func showFileDownloadMessage() {
            RMessage.showNotification(withTitle: RMessageText.fileDownloadTitle, subtitle: RMessageText.fileDownloadMsg, iconImage: #imageLiteral(resourceName: "Agremo_icon_44x44"), type: RMessageType.normal, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "OK", buttonCallback: {
                RMessage.dismissActiveNotification()
            }, at: RMessagePosition.navBarOverlay,
               canBeDismissedByUser: true)
        }
        static func showFileDownloadStatusMessage(success: String) {
            RMessage.showNotification(withTitle: RMessageText.fileDownloadTitle, subtitle: success, iconImage: #imageLiteral(resourceName: "Agremo_icon_44x44"), type: RMessageType.warning, customTypeName: nil, duration: 5.0, callback: {}, buttonTitle: "OK", buttonCallback: {
                RMessage.dismissActiveNotification()
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
    
    static func saveToDiskInDocDir(data: Data, filenameWithExtension: String) {
        
        let writeUrl = docDir.appendingPathComponent(filenameWithExtension)
        
        do {
            try data.write(to: writeUrl, options: .atomicWrite)
//            print("saveToDisk.docDir: data saved !!! all good...")
        } catch {
//            print("saveToDisk.docDir: catch. cant save data")
        }
        
    }
    
    static func saveToDisk(data: Data, inDirectory dir: URL , filenameWithExtension: String) {
        
        let writeUrl = docDir.appendingPathComponent(filenameWithExtension)
        
        do {
            //try data.write(to: writeUrl, options: .atomicWrite)
            try data.write(to: writeUrl)
//            print("saveToDisk.docDir: data saved !!! all good...")
        } catch {
//            print("saveToDisk.docDir: catch. cant save data")
        }
        
    }
    
    
    static var docDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var applicationSupportDir: URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    static var cachesDir: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    
    static func destinationUrl(fileName: String, ext: String) -> URL {
        return docDir.appendingPathComponent(fileName).appendingPathExtension(ext)
    }
}


extension DateFormatter {
    
    static var sharedDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        // Add your formatter configuration here
        //dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyyMM_ddHHmmss"
        return dateFormatter
    }()
}
