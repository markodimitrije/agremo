//
//  ServerRequest.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 13/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation

// MARK: - UPLOAD PROFILE PHOTO

struct ServerRequest {
    
    static func sendPingToAgremo(_ successHandler: @escaping (_ success: Bool?, _ error: Error?) -> Void) {
        
        let requestString = "https://app.agremo.com"
        
        guard let requestUrl = URL(string: requestString) else {return}
        
        let request = NSMutableURLRequest(url: requestUrl)
        
        request.timeoutInterval = Timeout.seconds10 // Timeout.secondsUltraFastTestTimeout
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            
            (data, response, error ) -> Void in
            
            if error != nil { // imas error
                print("error.localizedDescription = \(error!.localizedDescription)")
                successHandler(nil, error!)
                
            } else if let response = response as? HTTPURLResponse,
                response.statusCode == 200 { // HTTPStatus.OK
                
                successHandler(true, nil) // all good
                //successHandler(false, nil) // hard-coded
                //successHandler(nil, nil) // hard-coded
            } else {
                
                successHandler(false, nil)
                
            }
            
        })
        
        task.resume()
    }
 
    static func downloadAgremoZip(addr: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        
        guard let request = URLRequest.getRequest(addr: addr,
                                                  timeout: TimeOut.downloadZipArchive) else {return}
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
            
            guard err == nil,
                let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {completionHandler(nil); return}
            
            // ako si do ovde sve ok, onda imas ok data (trebalo bi...)
            
            completionHandler(data)
            
        }
        
        task.resume()
        
    }
    
}

enum Timeout {
    static let secondsUltraFastTestTimeout = 0.001
    static let seconds3 = 3.0
    static let seconds10 = 10.0
}

enum NetworkingErrorMessages {
    static let noConnection = "No connection could be established between device and Agremo. Please check device connectivity."
    static let unknown = "Unknown error occured. Please try again later."
}
