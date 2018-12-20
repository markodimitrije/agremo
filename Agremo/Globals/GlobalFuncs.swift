//
//  GlobalFuncs.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 28/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation

func isAgremoResourceDownloadUrl(response: URLResponse) -> Bool? {
    
    return response.url?.absoluteString.contains("results")
    
}

//func getDownloadFileInfo(response: URLResponse) -> (fileUrl: String, filename: String)? {
//
//    guard let response = response as? HTTPURLResponse else {
//        //print("nisam HTTPURLResponse!")
//        return nil
//    }
//
//    guard let url = response.url?.absoluteString, url.contains("results") else {
//        //print("nemam results!")
//        return nil
//    }
//
//    guard let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String else {
//        //print("nemam contentDisposition string")
//        return nil
//    }
//
//    guard let filename = contentDisposition.components(separatedBy: "filename=").last else {
//        //print("nemam filename!")
//        return nil
//    }
//
//    let final = timestamped(filename: filename)
//
//    return (url, final)
//}

func getDownloadFileInfo(downloadTask: URLSessionDownloadTask) -> (fileUrl: String, filename: String)? {
    
    guard let httpResponse = downloadTask.response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode) else {
            return nil
    }
    return getDownloadFileInfo(response: httpResponse)
}

func getDownloadFileInfo(response: URLResponse?) -> (fileUrl: String, filename: String)? {
    
    guard let response = response as? HTTPURLResponse,
        let url = response.url?.absoluteString, url.contains("results"),
        let tempName = url.components(separatedBy: "results").last else {
            return nil
    }
    
    guard let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String else {
        //print("nemam contentDisposition string")
        return nil
    }
    
    guard let filename = contentDisposition.components(separatedBy: "filename=").last else {
        //print("nemam filename!")
        return nil
    }
    
    let final = timestamped(filename: filename)
    
    let cleaned = tempName.replacingOccurrences(of: "/", with: "")
    
    return (cleaned, final)
}

func isDownloadFileUrl(_ adr: String) -> Bool {
    //return adr.contains("results")
    var copy = adr
    guard let last = copy.popLast() else {
        return adr.contains("results")
    }
    
    //return adr.contains("results") && last != "/"
    return adr.contains("results") && last == "/"
}

func getTempFilename(_ adr: String) -> String? {
    // https://app.agremo.com/results/8b1dacc013c64562b92f1989a50f3e38
    guard let tempFilename = adr.components(separatedBy: "results").last?.replacingOccurrences(of: "/", with: "") else {return nil}
    return tempFilename + "/" // jer tap na btn salje i "results/xyz" i "results/xyz/"
    
}

func timestamped(filename: String) -> String {
    let now = Date.init(timeIntervalSinceNow: 0)
    let timestamp = DateFormatter.sharedDateFormatter.string(from: now)
    
    return timestamp + "_" + filename
}

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
