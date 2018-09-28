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
            case .appLoadingToSlow: return appLoadingToSlowAlertVC(handler: handler)
        default: return nil
        }
        
    }
    
    func getAlertFor(alertType: AlertType, message: String?) -> UIAlertController? {
        
        switch alertType {
            case .pingAgremo: return getPingAgremoAlertVC(message: message)
        default: return nil
        }
        
    }
    
    // Privates
    
    private func getPingAgremoAlertVC(message: String?) -> UIAlertController {
        
        let title = AlertInfo.PingAgremoApp.title
        let message = message ?? AlertInfo.PingAgremoApp.message
        
        let okAction = UIAlertAction.init(title: AlertInfo.ok, style: .default, handler: nil)
        
        let alertVC = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        
        alertVC.addAction(okAction)
        
        return alertVC
        
    }
    
    private func appLoadingToSlowAlertVC(handler: ((UIAlertAction) -> () )?) -> UIAlertController? {
        let title = AlertInfo.appLoadingToSlow.title
        let msg = AlertInfo.appLoadingToSlow.message
        let yesTitle = AlertInfo.ok
        
        let alertVC = UIAlertController.init(title: title, message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction.init(title: yesTitle, style: .default, handler: handler)
        
        alertVC.addAction(okAction)
        
        return alertVC
        
    }

    
}
