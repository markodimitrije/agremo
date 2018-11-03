//
//  GlobalFuncs.swift
//  Agremo
//
//  Created by Marko Dimitrijevic on 28/09/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation

func isAgremoResourceDownloadUrl(response: URLResponse) -> (data: Data, filename: String)? {
    
    //print("isAgremoResourceDownloadUrl.response = \(response)")
    
    guard let resp = response as? HTTPURLResponse else { return nil }
    
    // ako imam "Content-Disposition" polje
    // i u njemu odrednicu "filename=" .... zasto nije json.....
    // i ako imam data na tom url koje su sadrzaj file-a
    
    guard let value = resp.allHeaderFields["Content-Disposition"] as? String,
        let filename = value.components(separatedBy: "filename=").last,
        let url = response.url,
        let data = try? Data.init(contentsOf: url) else {return nil}
    
    // onda vrati korisne stvari: data to save + filename, neko drugi zna path...
    
    let name = addTimestamp(atFilename: filename)
    
    return (data, name)
    
}

func addTimestamp(atFilename filename: String) -> String {
    let now = Date.init(timeIntervalSinceNow: 0)
    let timestamp = DateFormatter.sharedDateFormatter.string(from: now)
    
    return timestamp + "_" + filename
}
