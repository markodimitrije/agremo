//
//  Extensions.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 13/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

extension UIApplication {
    static var view: UIView? {
        return UIApplication.shared.keyWindow?.rootViewController?.view
    }
}
