//
//  BaseService.swift
//
//  Created by Boris Chirino on 18/5/17.
/*
 Copyright 2017 Boris Chirino fernandez
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import Alamofire




//--------------------------------    E N U M S    ----------------------------



public enum APIErrorCodes :Int{
    case invalidEmail     = 601
    case mommitServerFail = 501
    case oaUthFail        = 401
    case missingParameter = 900
    case serverError      = 500 //internal server error
    case serializationError = 700 //internal server error
    case networkError       = 800 //internal server error
}









public enum APIError: Error {
    
    case userRegistrationFailure(code :APIErrorCodes, reason: String?)
    
    case loginFailure(code :APIErrorCodes, reason: String?)
    
    case missingParameter
    
    case jsonSerialization
    
    case notLoggedIn
    
    case unknownError
    
    case networkError(error :NSError)
    
    public var errorInstance : NSError {
        switch self {
        case .userRegistrationFailure(let code, let reason):
            return NSError.errorWithContent(code.rawValue, failureDescr: reason)
            
        case .loginFailure(let code, let reason):
            return NSError.errorWithContent(code.rawValue, failureDescr: reason)
            
        case .missingParameter:
            return NSError.errorWithContent(APIErrorCodes.MissingParameter.rawValue , failureDescr: NSLocalizedString("Usuario incorrecto. Revisa que el usuario este registrado", comment: "") )
            
        case .jsonSerialization:
            return NSError.errorWithContent(APIErrorCodes.SerializationError.rawValue , failureDescr: NSLocalizedString("Error transformando los datos recibidos", comment: "") )
            
        case .networkError(let error):
            return error
            
        case .notLoggedIn:
            return NSError.errorWithContent(0, failureDescr: "El usuario no se ha iniciado sesión o la sesión ha expirado")
            
        case .unknownError:
            return NSError.errorWithContent(APIErrorCodes.ServerError.rawValue, failureDescr: "Ocurrió un fallo intentando la comunicación con el servidor")
            
        }
    }
}





//--------------------------------    P R O T O C O L S     ----------------------------------------------

protocol API_ENUM_STANDARDS {
    func configuration() -> (path: String, verb :Alamofire.HTTPMethod)
}






//--------------------------------    E X T E N S I O N S    ---------------------------------------------
extension String{
    func transformPath(_ c : CVarArg ...) -> String? {
        
        var result :String = self
        let elements = self.components(separatedBy: "*")
        var n = elements.filter { (element) -> Bool in
            return element.characters.first == "/"
        }
        var i = 0
        
        for element in c {
            result = result.replacingOccurrences(of: "*"+n[i]+"*", with:String(describing: element))
            i = i + 1
        }
        
        return result
    }
}


extension API_ENUM_STANDARDS {
    func configuration() -> (path: String, verb :Alamofire.HTTPMethod)? { return nil }
}





//--------------------------------    C O N S T A N T S    --------------------------------


let SHConfiguration: Configuration =  Configuration.shared(BaseService.self)

let i2coreBasePath : String = "/api/enua/es"

let NOTIFY_USER_NEED_LOGIN = "NOTIFY_USER_NEED_LOGIN"














//--------------------------------     C L A S S    B E G I N   --------------------------------


open class BaseService :NSObject{
    
    typealias RouterGenericResult = (path: String, parameters:  Dictionary<String, AnyObject>?)
    
    internal static let baseURLString   = (SHConfiguration.environmentConfiguration?.endpoint)!
    
    typealias SuccessServiceCompletion = (_ response :Dictionary<String, AnyObject>) -> Void
    
    typealias FailureServiceCompletion = (_ error :NSError) -> Void
    
    var APIToken :TOKEN? = nil
    
    
    internal var defaultHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders ?? [:]
    
    internal let configuration = URLSessionConfiguration.ephemeral
    
    internal var manager : SessionManager!
    
    static let sharedInstance = BaseService()
    
    open var dateFormatter :DateFormatter
    
    
    //MARK:
    //MARK CONSTRUCTORS
    override init() {
        
        if let data = UserDefaults.standard.object(forKey: "api_token") as? Data {
            self.APIToken = NSKeyedUnarchiver.unarchiveObject(with: data) as? TOKEN
        }
        
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        //_formatter.dateStyle = .NoStyle
        dateFormatter.amSymbol = ""
        dateFormatter.pmSymbol = ""
        dateFormatter.dateFormat = "'T'HH:mm"
        dateFormatter.locale = Locale.current
        dateFormatter.calendar = Calendar.current
        //(localeIdentifier: "en_US_POSIX")
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        //dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 360000)
        
        //dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        defaultHeaders["DNT"] = "1 (Do Not Track Enabled)"
        defaultHeaders["APP"] = "ENUA iOS"
        
        configuration.httpAdditionalHeaders = defaultHeaders
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.networkServiceType = .default
        
        manager = SessionManager(configuration: configuration)
    }
    
    

    
    
    
    
    
    // ---------------------------------------------------------------------------------
    // --------------------------------   W E B    S E R V I C E   M E T H O D S  ------------------------
    // -------------- C O M M O N    M E T H O D S   U S E D    F O R   C H I L D  S   C L A S S E S  --------------------
    // ------------------------------------------------------------------------------
    
    
    
    
    
    
    
    

    
    
    

    
    
    
    //MARK:
    //MARK: TIME HELPER
    // ------------------------------------------------------------------------------------------------------------------------------
    func strTimeTo2kDate(_ hour :String) -> Date {
    // ------------------------------------------------------------------------------------------------------------------------------

        let time = "T"+hour
        return   self.dateFormatter.date(from: time)!
    }
    
    
    
    
    
    
    
    
    //MARK:
    //MARK: Configure URL for all webservices
    // ------------------------------------------------------------------------------------------------------------------------------
    class func configureURL<T: API_ENUM_STANDARDS>(foroperation operation : T ) -> NSMutableURLRequest{
    // ------------------------------------------------------------------------------------------------------------------------------
        var URL :Foundation.URL
        
        URL = Foundation.URL(string: BaseService.baseURLString+i2coreBasePath)!

        if let op = operation as? USER_API_OPERATION {
           if op == USER_API_OPERATION.LoginUser {
                URL = Foundation.URL(string: BaseService.baseURLString)!
            }
        }
        
        var URLRequest = NSMutableURLRequest()
        
        let requestURL = URL.URLByAppendingPathComponent(operation.configuration().path)
        URLRequest = NSMutableURLRequest(URL: requestURL!)
        URLRequest.HTTPMethod = operation.configuration().verb.rawValue
        return URLRequest
    }
    
    
    
    //    func transformPath(c : CVarArgType ...) -> String? {

    
    class func configureUR<T: API_ENUM_STANDARDS>( withParams params :CVarArg...,  foroperation operation : T ) -> NSMutableURLRequest{
        // ------------------------------------------------------------------------------------------------------------------------------
        var URL :Foundation.URL
        
        URL = Foundation.URL(string: BaseService.baseURLString+i2coreBasePath)!
        
        if let op = operation as? USER_API_OPERATION {
            if op == USER_API_OPERATION.LoginUser {
                URL = Foundation.URL(string: BaseService.baseURLString)!
            }
        }
        
        var URLRequest = NSMutableURLRequest()

        
        var result = operation.configuration().path
        let elements = result.componentsSeparatedByString("*")
        var n = elements.filter { (element) -> Bool in
            if element.characters.first == "/"  { return false } else {return true}
        }
        var i = 0
        
        for element in params {
            result = result.stringByReplacingOccurrencesOfString("*"+n[i]+"*", withString:String(element))
            i = i + 1
        }

        
        
        let requestURL = URL.URLByAppendingPathComponent(result)
        URLRequest = NSMutableURLRequest(URL: requestURL!)
        URLRequest.HTTPMethod = operation.configuration().verb.rawValue
        return URLRequest
    }

    
    
    
    
    
    
    
    
    
    //MARK:
    //MARK: Assemble urlrequest, with endpoint and htt method
    // ------------------------------------------------------------------------------------------------------------------------------
    class func routerResultAssemble<T: API_ENUM_STANDARDS>(foroperation operation : T, parameters: Dictionary<String, AnyObject>?) -> RouterGenericResult {
    // ------------------------------------------------------------------------------------------------------------------------------
        return (operation.configuration().path, parameters) as RouterGenericResult
    }
    
    
    
    
    
    
    
    
    
    
    
    //MARK:
    //MARK parse json response
    // ------------------------------------------------------------------------------------------------------------------------------
    class func parseStatus(_ resp:(Response<AnyObject, NSError>),  success :SuccessServiceCompletion, failure :FailureServiceCompletion){
    // ------------------------------------------------------------------------------------------------------------------------------

        debugPrint(resp.request!.allHTTPHeaderFields)
        debugPrint(resp.request!.HTTPMethod)

        switch resp.result {
        case .Success(let value):
            if resp.response?.statusCode == 200 {                       //response is 200
                // check if response contain a valid json
                if let jsonResponse = value as? Dictionary<String, AnyObject> {
                    
                    // check status key inside dictionary
                    if let jsonStatus = jsonResponse["status"] as? Int {
                        
                        //if status = 0 means the response json is an error
                        if  jsonStatus == 0 {
                            if let errorDictionary = jsonResponse["error"] as? Dictionary<String, AnyObject>{
                                if let errorCodeKey = errorDictionary["code"] as? String {
                                    if  let errorDescriptionKey = errorDictionary["msg"] as? String{
                                        let apierror = NSError(domain: errorCodeKey, code: 0,  userInfo: [NSLocalizedDescriptionKey:errorDescriptionKey])
                                        failure(error: apierror)
                                    }
                                }else{
                                    failure(APIError.unknownError.errorInstance)
                                }
                            }
                            
                        }else if jsonStatus == 1 {
                            success(response: jsonResponse)
                        }
                    }
                    
                    
                } else { // if response is not a json object
                    let error =  APIError.jsonSerialization.errorInstance
                    failure(error)
                }
                
                
            }else if resp.response?.statusCode == 403 {    // response is 403
                if let jsonResponse = value as? Dictionary<String, AnyObject> {
                    let errorObject = jsonErrorToErrorObject(jsonResponse)
                    failure(error: errorObject)
                }
                
            }else if resp.response?.statusCode == 400 {    // response is 400
                    if let jsonResponse = value as? Dictionary<String, AnyObject> {
                        let errorObject = jsonErrorToErrorObject(jsonResponse)
                        if errorObject.code == 1040 {
                            // refresh token is invalid, wich mean user has logged in into another device
                            // and access_token , refresh_token are changed
                            // notify app that user must loged back back in
                            //nullify token
                            BaseService.removeToken()
                            
                            let defaultCenter = NotificationCenter.default
                            defaultCenter.post(name: Notification.Name(rawValue: NOTIFY_USER_NEED_LOGIN), object: nil)
                        }
                        failure(error: errorObject)
                    }
                
            }else {                                         // response status code is not 200.. or 403 Server Error
                let error =  APIError.unknownError.errorInstance
                failure(error)
            }
            
        case .Failure(let error):
            
            failure(error: error)
            SpeedLog.print(error)
        }
    }
    
    
    
    
    
    
    
    
    
    
    //MARK:
    //MARK parse json response
    // ------------------------------------------------------------------------------------------------------------------------------
    class func parseStatus(_ resp:(Response<NSData, NSError>),  success :SuccessServiceCompletion, failure :FailureServiceCompletion){
    // ------------------------------------------------------------------------------------------------------------------------------
        switch resp.result {
        case .Success(let value):
            if resp.response?.statusCode == 200 {
                // check if response contain a valid json
                do{
                    let jsonResponse = try JSONSerialization.JSONObjectWithData(value, options: .AllowFragments) as? Dictionary<String, AnyObject>
                    
                    // check status key inside dictionary
                    if let jsonStatus = jsonResponse!["status"] as? Int {
                        
                        //if status = 0 means the response json is an error
                        if  jsonStatus == 0 {
                            failure(error: BaseService.jsonErrorToErrorObject(jsonResponse!))
                            break
                        }else if jsonStatus == 1 {
                            success(response: jsonResponse!)
                            break
                        }
                    }
                }catch {}
                
                
            }else {   // response status code is not 200.. Server Error
                if let error =  resp.result.error {
                    failure(error: error)
                }else {
                    do{
                        let json = try JSONSerialization.JSONObjectWithData(value, options: .AllowFragments) as? Dictionary<String, AnyObject>
                        let errorObject = BaseService.jsonErrorToErrorObject(json!)
                        failure(error: errorObject)
                        
                    }catch {}
                    
                    let error =  APIError.unknownError.errorInstance
                    failure(error)
                }
            }
            
        case .Failure(let error):
            
            failure(error: error)
            SpeedLog.print(error)
        }
    }
    
    

    
    
    
    
    
    
    
    
    //MARK:
    // Convert error json into NSERROR instance
    // ------------------------------------------------------------------------------------------------------------------------------
    fileprivate class func jsonErrorToErrorObject(_ dictionary : Dictionary<String, AnyObject>) -> NSError{
    // ------------------------------------------------------------------------------------------------------------------------------

        var errorResult :NSError =  APIError.unknownError.errorInstance
        
        if let errorDictionary = dictionary["error"] as? Dictionary<String, AnyObject> {

            if let errorCodeKey = errorDictionary["code"] as? String {
                if  let errorDescriptionKey = errorDictionary["msg"] as? String{
                    errorResult = NSError(domain: errorCodeKey, code: 0,  userInfo: [NSLocalizedDescriptionKey:errorDescriptionKey])
                }
            }
        }else if let errorDescriptionKey = dictionary["error_description"] as? String {
            errorResult = NSError(domain: "REFRESH_TOKEN", code: 1040,  userInfo: [NSLocalizedDescriptionKey:errorDescriptionKey])
        }
        return errorResult
    }
    
    
    


    
    
    
    
    
    
    
    
    
    //MARK:
    // ------------------------------------------------------------------------------------------------------------------------------
    internal  class func storeToken(withData: Dictionary<String, AnyObject>){
    // ------------------------------------------------------------------------------------------------------------------------------

        sharedInstance.APIToken = TOKEN(access_t: (withData["access_token"] as? String)!,
                                          expire: (withData["expires_in"]?.doubleValue)!,
                                            type: (withData["token_type"] as? String)!,
                                       refresh_t: (withData["refresh_token"] as? String)!)
        let data = NSKeyedArchiver.archivedDataWithRootObject(sharedInstance.APIToken!)
        UserDefaults.standardUserDefaults().setObject(data, forKey: "api_token")
    }


    class func removeToken(){
        sharedInstance.APIToken = nil
        UserDefaults.standard.removeObject(forKey: "api_token")
    }
    
}




extension NSError {
    func toConsole()  {
        print("** \n \(self.localizedDescription) ** \n")
    }
    //            return NSError.errorWithContent(code.rawValue, failureDescr: reason)

    func errorWithContent(NSInteger :code, failureDescr :String) -> Error {
        return NSError.init(domain: "WSDomain", code: code, userInfo: [NSLocalizedDescriptionKey:failureDescr])
    }
}


extension Dictionary {
    func toJson() {
        print(self, separator: "\n", terminator: "")
    }
}

