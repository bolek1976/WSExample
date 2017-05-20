//
//  WebServices.swift
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


enum USER_API_OPERATION : API_ENUM_STANDARDS {
    case RefreshToken
    case LoginUser
    case CreateUser
    case EditUser
    case ViewUser
    case UploadFile
    case ResetPassword
    
    func configuration() -> (path: String, verb :Alamofire.HTTPMethod) {
        switch self {
        case .LoginUser:
            return ("/oauth/v2/token", Alamofire.HTTPMethod.post)
        case .RefreshToken:
            return ("/oauth/v2/token", Alamofire.HTTPMethod.post)
        case .CreateUser:
            return ("/user", Alamofire.HTTPMethod.post)
        case .EditUser:
            return ("/user", Alamofire.HTTPMethod.put)
        case .ViewUser:
            return ("/user", Alamofire.HTTPMethod.get)

        }
    }
}





//MARK:
//MARK: CLASS BEGIN
public final class UserWebService: BaseService {
    
    
    private enum UserRouter: URLRequestConvertible{
    
        // mandatory to conform to urlrequestconfertible
        var URLString : String { return ""}
        

        //ConfigRouter URLREQUEST VARIABLE
        private var URLRequest: NSMutableURLRequest {
            
            var URLRequest = NSMutableURLRequest()

            //(URL: URL.URLByAppendingPathComponent(result.path)!)
            let encoding = Alamofire.JSONEncoding
            
            let result: RouterGenericResult = { 
                switch self {
                case .Login(let user, let pass):
                    URLRequest = BaseService.configureURL(foroperation: USER_API_OPERATION.LoginUser)
                   return BaseService.routerResultAssemble(foroperation: USER_API_OPERATION.LoginUser,
                                                           parameters: [
                                                             "username" : user as AnyObject,
                                                             "password" : pass as AnyObject,
                                                            "grant_type": "password" as AnyObject,
                                                             "client_id": clientid as AnyObject,
                                                         "client_secret": secret])
                    
                
                case .RefreshToken(let refresh_t):
                    URLRequest = BaseService.configureURL(foroperation: USER_API_OPERATION.LoginUser)
                    return BaseService.routerResultAssemble(foroperation: USER_API_OPERATION.LoginUser ,
                                                            parameters: [
                                                                "refresh_token": refresh_t,
                                                                  "grant_type" : "refresh_token",
                                                                   "client_id" : clientid,
                                                               "client_secret" : secret])
                    
                    
                case .CreateUser( let data):
                    URLRequest = BaseService.configureURL(foroperation: USER_API_OPERATION.CreateUser)
                    return BaseService.routerResultAssemble(foroperation: USER_API_OPERATION.CreateUser, parameters: data)
                    

                }
            }()

            
            //inject api token in to headers
            if let APITOKEN = UserWebService.sharedInstance.APIToken{
                URLRequest.setValue("Bearer \(APITOKEN.access_token)", forHTTPHeaderField: "Authorization")
            }

            
            let returnObject :NSMutableURLRequest = encoding.encode(URLRequest, parameters: result.parameters).0
            return returnObject
        }
        

        //ConfigRouter CASE
        case Login(username :String, password :String)
        case RefreshToken(refreshToken: String!)
        case CreateUser(data :Dictionary<String, AnyObject>)

    }
    
    
    
    
    
    
    
    
    
    // ----------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------   W E B    S E R V I C E   M E T H O D S  --------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
    
    
    
    
    //MARK:
    // Check if app is logged in, if yes and the token is expired refresh it.
    // else fail
    // ------------------------------------------------------------------------------------------------------------------------------
    internal class func checkAPIAutorization( success :(token :TOKEN)->Void , failed : FailureServiceCompletion ){
    // ------------------------------------------------------------------------------------------------------------------------------

        //check if we got token and if its valid
        let tk = UserWebService.sharedInstance.APIToken
        let expired = UserWebService.sharedInstance.APIToken?.isExpired
        
        
        
        if tk == nil { // if nil, user never log in
            failed(error: APIError.NotLoggedIn.errorInstance)
        }else{ // token is not nil , check if is expired
            if expired! == true {  //is expired so refresh it
                
                UserWebService.refreshToken({ (response) in
                    
//                    self.sharedInstance.APIToken = TOKEN(
//                        access_t: (response["access_token"] as? String)!,
//                          expire: (response["expires_in"]?.doubleValue)!,
//                            type: (response["token_type"] as? String)!,
//                       refresh_t: (response["refresh_token"] as? String)!)
//                    
//                    //store it
//                    let data = NSKeyedArchiver.archivedDataWithRootObject(self.sharedInstance.APIToken!)
//                    NSUserDefaults.standardUserDefaults().setObject(data, forKey: "api_token")
                    
                    success(token: self.sharedInstance.APIToken!)
                    
                    }, failure: { (error) in
                        failed(error: error)
                })
                
            }else { // not expired, return it
                success(token: self.sharedInstance.APIToken!)
                
            }
        }
    }

    
    
    
    
    
    
    
    
    
    
    
    
    //MARK:
    //MARK: refresh token
    // not intended by being called directly
    // ------------------------------------------------------------------------------------------------------------------------------
    private class func refreshToken( success :SuccessServiceCompletion, failure :FailureServiceCompletion) {
    // ------------------------------------------------------------------------------------------------------------------------------
        
        if let currentRefreshToken = sharedInstance.APIToken?.refresh_token {
         
            sharedInstance.manager.request(UserRouter.RefreshToken(refreshToken: currentRefreshToken))
                .responseJSON { (response) in response.result
                    
                    switch response.result {
                    case .Success(let value):
                        if response.response?.statusCode == 200 {
                            response
                            let responseJson = value as! Dictionary<String, AnyObject>
                            UserWebService.storeToken(withData: responseJson)
                            success(response: responseJson)
                        } else {
                            let message = NSLocalizedString("Fallo del servicio reautorizando cuenta", comment: "")
                            let error =  APIError.LoginFailure(code: .OAUthFail, reason: message).errorInstance
                            failure(error: error)
                        }
                    case .Failure(let error):
                        failure(error: error)
                        SpeedLog.print(error)
                    }
                    
            }
            
            
        }else {
            failure(error: NSError.errorWithContent(0, failureDescr: "No se ha iniciado sesion <APTK>"))
        }
        
        
    }

    
    
    
    
    
    

    
    //MARK:
    //MARK:create user
    // ------------------------------------------------------------------------------------------------------------------------------
    class func createUser( registrationData :Dictionary<String, AnyObject>, success :SuccessServiceCompletion, failure :FailureServiceCompletion){
    // ------------------------------------------------------------------------------------------------------------------------------
        sharedInstance.APIToken = nil
        
        UserWebService.login(username: "master", password: "master", success: { (response) in
            
                sharedInstance.manager.request(UserRouter.CreateUser(data: registrationData))
                    .responseJSON(completionHandler: { (response) in
                        SpeedLog.print(" createUser data : \(response)");

                        parseStatus(response, success: { (response) in
                            //remove token because is master
                            sharedInstance.APIToken = nil

                            success(response:response)
                            }, failure: { (error) in
                                failure(error: error)
                        })
                    })

            }) { (error) in //fail login with master
                failure(error: error)
                
        }
        
     }
    

    
        
        

    
    
    
    
    
    
    //MARK:
    //MARK:Login with provided username and password
    //------------------------------------------------------------------------------------------------------------------------------
    class func login(username username :String!, password :String!, success :SuccessServiceCompletion, failure :FailureServiceCompletion){
    // ------------------------------------------------------------------------------------------------------------------------------
        
        sharedInstance.manager.request(UserRouter.Login(username: username, password: password).URLRequest)
            .responseJSON { (response) in
                response.result
                SpeedLog.print(" Login data: \(response)");
                /*
                Answers.logCustomEventWithName("Login-Service",
                    customAttributes: [
                        "request_URL": (response.request?.URL?.absoluteString)!,
                        "headers": (response.request?.allHTTPHeaderFields.debugDescription)!
                    ])
                */
                
                switch response.result {
                case .Success(let value):
                    if response.response?.statusCode == 200 {
                        response
                        let responseJson = value as! Dictionary<String, AnyObject>
                        UserWebService.storeToken(withData: responseJson)
                        success(response: responseJson)
                    } else {
                        let message = NSLocalizedString("Fallo en la autenticación, verifique usuario y/o contraseña", comment: "")
                        let error =  APIError.LoginFailure(code: .OAUthFail, reason: message).errorInstance
                        failure(error: error)
                    }
                case .Failure(let error):
                    failure(error: error)
                    SpeedLog.print(error)
                }
         
        }

    }
    
    
    
    
    
    
    
    
    
    //MARK:
    //MARK: GET user details
    // ------------------------------------------------------------------------------------------------------------------------------
    class func getCurrentUserDetail( success :SuccessServiceCompletion, failure :FailureServiceCompletion){
    // ------------------------------------------------------------------------------------------------------------------------------
        UserWebService.checkAPIAutorization({ (token) in
            
            sharedInstance.manager.request(UserRouter.UserDetail() )
                .responseJSON(completionHandler: { (response) in
                    response.result
                    
                    parseStatus(response, success: { (response) in
                        success(response:response)
                        }, failure: { (error) in
                            failure(error: error)
                    })
                })

            
            }) { (error) in
                failure(error: error)
        }
        
    }

    
    
    
    
    




