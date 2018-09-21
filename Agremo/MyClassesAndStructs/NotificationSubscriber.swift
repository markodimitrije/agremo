//
//  NotificationSubscriber.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 21/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

struct NotificationSubscriber {
    
    static func startToObserveNotifications(onListener vc: UIViewController,
                                            dict: [NSNotification.Name: Selector]) {
        
        let _ = dict.keys.map {NotificationCenter.default.addObserver(vc,
                                                                      selector: dict[$0]!,
                                                                      name: $0,
                                                                      object: nil)}
        
    }
    
    static func stopToObserveNotifications(onListener vc: UIViewController, names: [NSNotification.Name]) {
        
        let _ = names.map {NotificationCenter.default.removeObserver(vc, name: $0, object: nil)}
        
    }
}
