//
//  DummyVC.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 12/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit

class DummyVC: UIViewController {

    private enum Segue {
        static let showMainVC = "showMainVC"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegue(withIdentifier: Segue.showMainVC, sender: self)
    }

}
