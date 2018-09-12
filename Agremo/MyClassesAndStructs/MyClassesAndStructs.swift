//
//  MyClassesAndStructs.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

struct ApplicationFrameCalculator {
    static func getTotalHeightForNavBarAndStatusBar(vc: UIViewController) -> CGFloat {
        var height: CGFloat = 100
        guard let navBarHeight = vc.navigationController?.navigationBar.bounds.height else {
            return height
        }
        height = navBarHeight + UIApplication.shared.statusBarFrame.height
        return height
    }
}
