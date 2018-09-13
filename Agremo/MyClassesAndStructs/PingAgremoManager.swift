//
//  assasasasa.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 13/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

struct PingAgremoManager {
    
    // ova func zna na osnovu parametara da li treba da prikazes alert ili ne...
    func getAlertForResponse(success: Bool?, error: Error?) -> UIAlertController? {
        
        guard let success = success else {
            
            let errorMsg = error?.localizedDescription ?? NetworkingErrorMessages.noConnection
            
            return AlertManager().getAlertFor(alertType: .pingAgremo, message: errorMsg)
        }
        if !success {
            
            return AlertManager().getAlertFor(alertType: .pingAgremo, message: NetworkingErrorMessages.unknown)
            
        }
        
        return nil // all good
        
    }
    
}
