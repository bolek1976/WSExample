//
//  Token.swift
//
//  Created by Boris Chirino on 18/5/17.
/*
 Copyright 2017 Boris Chirino fernandez
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation


public class TOKEN : NSObject, NSCoding {
    var access_token  :String
    var expires_in    :TimeInterval
    var token_type    :String
    var refresh_token :String!
    private var lastModified :NSDate
    
    var isExpired :Bool {
        get {
            return   self.lastModified.timeIntervalSinceNow <= 0
        }
        set {}
    }
    
    init(access_t :String, expire : TimeInterval, type: String, refresh_t :String) {
        self.access_token = access_t
        self.expires_in = expire
        self.token_type = type
        self.refresh_token = refresh_t
        self.lastModified = NSDate(timeIntervalSinceNow: expire)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let access_token = aDecoder.decodeObject(forKey: "access_token") as? String,
            let expires_in = aDecoder.decodeObject(forKey: "expires_in") as? Double,
            let token_type = aDecoder.decodeObject(forKey: "token_type") as? String,
            let refresh_token = aDecoder.decodeObject(forKey: "refresh_token") as? String,
            let lastModified = aDecoder.decodeObject(forKey: "lastModified") as? NSDate
            else {
                return nil
        }
        
        self.init(access_t :access_token , expire : expires_in, type: token_type , refresh_t :refresh_token )
        
        self.lastModified = lastModified

    }

    public func encode(with aCoder: NSCoder){
        aCoder.encode(self.access_token, forKey: "access_token")
        aCoder.encode(self.expires_in, forKey: "expires_in")
        aCoder.encode(self.token_type, forKey: "token_type")
        aCoder.encode(self.refresh_token, forKey: "refresh_token")
        aCoder.encode(self.lastModified, forKey: "lastModified")
    }


    
}
