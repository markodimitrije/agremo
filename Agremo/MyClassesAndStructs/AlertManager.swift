//
//  AlertManager.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

struct AlertManager {
    
    // API
    
    func getAlertFor(alertType: AlertType, handler: ((UIAlertAction) -> () )?) -> UIAlertController? {
        
        switch alertType {
            case .quitAgremoApp: return getQuitAppAlertVC(handler: handler)
        }
        
    }
    
    // Privates
    
    private func getQuitAppAlertVC(handler: ((UIAlertAction) -> () )?) -> UIAlertController? {
        let title = AlertInfo.QuitAgremoApp.title
        let msg = AlertInfo.QuitAgremoApp.message
        let noTitle = AlertInfo.QuitAgremoApp.no
        let yesTitle = AlertInfo.QuitAgremoApp.yes
        
        let alertVC = UIAlertController.init(title: title, message: msg, preferredStyle: .alert)
        
        let noAction = UIAlertAction.init(title: noTitle, style: .default, handler: nil)
        let yesAction = UIAlertAction.init(title: yesTitle, style: .default, handler: handler)
        
        alertVC.addAction(yesAction)
        alertVC.addAction(noAction)
        
        return alertVC
        
    }
    
}
