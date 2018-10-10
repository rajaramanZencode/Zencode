//
//  SocialLoginController.swift
//  CircleIT
//
//  Created by CSS on 11/04/18.
//  Copyright © 2018 Zencode. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import GoogleSignIn
import Alamofire
import TwitterKit
import SwiftInstagram
enum LoginType{ 
    case Facebook
    case Twitter
    case Google
    case InstaGram
}
enum ErrorType:Int,Decodable
{
    case AlertMessage = 1
    case onScreen = 0
    case None = 2
    
}
struct APIError:Decodable
{
    let status:Bool
    let error:ErrorDetail
    struct ErrorDetail:Decodable
    {
        let errorCode:Int
        let errorType:ErrorType
        let displayMessage:String
    }
}
struct INSTAGRAM_IDS {
    
    static let INSTAGRAM_AUTHURL = "https://api.instagram.com/oauth/authorize/"
    
    static let INSTAGRAM_APIURl  = "https://api.instagram.com/v1/users/"
    
    static let INSTAGRAM_CLIENT_ID  = "a9c30caa648f40159388d57c880a6114"
    
    static let INSTAGRAM_CLIENTSERCRET = "a7a448509b5949a2b20764d02e80078b"
    
    static let INSTAGRAM_REDIRECT_URI = "http://www.zencode.guru/"
    
    static let INSTAGRAM_ACCESS_TOKEN =  ""
    
    static let INSTAGRAM_SCOPE = "basic+public_content+comments+relationships" 
}

struct UserInfo
{
    var firstName:String
    var lastName:String
    var dob:String
    var email:String
    var fullName:String
    var gender:String
    var accesstoken:String
}
protocol SocialLoginDelegate:class
{
    func recievedUserInfo(userDetails:UserInfo)
    func errorRecieved(error:APIError)
}

class SocialLoginController:NSObject
{
    var loginType:LoginType = .Facebook
    weak var delegate:SocialLoginDelegate?
    var vcParent:UIViewController
    init(withType:LoginType,controller:UIViewController)
    {
        vcParent=controller
        loginType=withType
        super.init()
        switch withType
        {
        case .Facebook:
            self.facebookLogin()
        case .Google:
            self.googleLogin()
        case .Twitter:
            self.twitterLogin()
        case .InstaGram:break
            self.instagramLogin()
        }
    }
    func instagramLogin()
    {
//        let api = Instagram.shared
//        api.login(from: navigationController!, success:
//        {

//          let user = api.user(_ userId: String, success: SuccessHandler<InstagramUser>?, failure: FailureHandler?)

            // Do your stuff here ...
//        }, failure: { error in
//            print(error.localizedDescription)
//        })
        
//        // Returns whether a user is currently authenticated or not
//        let _ = api.isAuthenticated
//
//            // Do your stuff here ...
//        }, failure: { error in
//            print(error.localizedDescription)
//        })
//        
////        // Returns whether a user is currently authenticated or not
////        let _ = api.isAuthenticated
////
////        // Logout
////        api.logout()
    }
    func twitterLogin()
    {
        var userDetails:UserInfo=UserInfo(firstName: "", lastName: "", dob: "", email: "", fullName: "", gender: "", accesstoken: "")
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            if (session != nil) {
                userDetails.firstName=(session?.userName)!
                userDetails.accesstoken=(session?.authToken)!
                self.getMailIDFromTwitter(userDetail: userDetails)
                
            } else {
                self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:(error?.localizedDescription)!)))
            }
        })
//        [[[TWTRTwitter sharedInstance] TWTRAPIClient] loadUserWithID:[session userID]
//            completion:^(TWTRUser *user,
//            NSError *error)
//            {
//            // handle the response or error
//            if (![error isEqual:nil]) {
//            NSLog(@"Twitter info   -> user = %@ ",user);
//            NSString *urlString = [[NSString alloc]initWithString:user.profileImageLargeURL];
//            NSURL *url = [[NSURL alloc]initWithString:urlString];
//            NSData *pullTwitterPP = [[NSData alloc]initWithContentsOfURL:url];
//            UIImage *profImage = [UIImage imageWithData:pullTwitterPP];
//
//            } else {
//            NSLog(@"Twitter error getting profile : %@", [error localizedDescription]);
//            }
//            }];
        
       

    }
    func getMailIDFromTwitter(userDetail:UserInfo)
    {
        var userDetails=userDetail
        let client = TWTRAPIClient.withCurrentUser()
        client.loadUser(withID: TWTRAPIClient.withCurrentUser().userID!, completion: { (user, errorTweer) in
            if errorTweer==nil
            {
               userDetails.firstName = (user?.name)!
                client.requestEmail { email, error in
                    if (email != nil) {
                        userDetails.email=email!
                        self.delegate?.recievedUserInfo(userDetails: userDetails)
                    } else
                    {
                        self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage: "unabel to get email from twitter please allow our app to get it")))
                        print("Unable get email from twitter")
                    }
                }
            }
        })
        
    }
    func googleLogin()
    {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes=["https://www.googleapis.com/auth/userinfo.email","https://www.googleapis.com/auth/userinfo.profile","https://www.googleapis.com/auth/plus.login"," https://www.googleapis.com/auth/plus.me"]
        GIDSignIn.sharedInstance().signIn()

    }
    func facebookLogin()
    {
        let loginManager = FBSDKLoginManager.init()
        loginManager.loginBehavior = .native
        loginManager.logIn(withReadPermissions: ["email","public_profile","user_friends","user_birthday"], from: vcParent, handler: {result,error in
            if (result?.isCancelled)!
            {
                self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .None, displayMessage:"User cancelled login")))
            }
            else if (result?.declinedPermissions.count)! > 0
            {
                self.delegate?.errorRecieved(error:APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:"Unable to get \(result?.declinedPermissions)!")))
            }
            else if error==nil
            {
                self.getFBUserData()
            }
            else
            {
                self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:(error?.localizedDescription)!)))
            }
        })
    }
    func getFBUserData()
    {
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email,first_name,middle_name,last_name, picture.type(large),gender,age_range,birthday"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    
                    var userDetails:UserInfo=UserInfo(firstName: "", lastName: "", dob: "", email: "", fullName: "", gender: "", accesstoken: "")
                    if let dictResult = result! as? NSDictionary
                    {
                        if let userID = dictResult.object(forKey: "id") as? String
                        {
                            
                        }
                        if let firstN = dictResult.object(forKey: "first_name") as? String {
                            userDetails.firstName=firstN
                        }
                        if let lastN = dictResult.object(forKey: "last_name") as? String {
                            userDetails.lastName=lastN
                        }
                        if let userMail = dictResult.object(forKey: "email") as? String {
                            userDetails.email=userMail
                        }
                        if let userGender = dictResult.object(forKey: "gender") as? String
                        {
                        }
                        if let userAge = dictResult.object(forKey: "birthday") as? String {
//                            let ageComponents = userAge.components(separatedBy: "/")
//                            let dateDOB = Calendar.current.date(from: DateComponents(year:
//                                Int(ageComponents[2]), month: Int(ageComponents[0]), day:
//                                Int(ageComponents[1])))!
                            let inputFormatter = DateFormatter()
                            inputFormatter.dateFormat = "MM/dd/yyyy"
                            let showDate = inputFormatter.date(from: userAge)
                            inputFormatter.dateFormat = "MM-dd-yyyy"
                            let resultString = inputFormatter.string(from: showDate!)
                            userDetails.dob=resultString
                            
                        }
                        userDetails.accesstoken=FBSDKAccessToken.current().tokenString
                        self.delegate?.recievedUserInfo(userDetails: userDetails)
                    }
                    
                }
                else
                {
                    print("FacebbokError:\(String(describing: error?.localizedDescription))")
                }
            })
        }
    }
    func showError(error:APIError)
    {
        self.delegate?.errorRecieved(error:error)

    }
}
extension SocialLoginController:GIDSignInDelegate,GIDSignInUIDelegate
{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!)
    {
        if let error = error {
            self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:error.localizedDescription)))
        } else {
           
            let gplusapi = "https://www.googleapis.com/plus/v1/people/\(user.userID!)?key=AIzaSyDIFABc24DViYOyyff2GMq86lhN_W9peXY"
            let url = NSURL(string: gplusapi)
           let  header = ["Content-Type":"application/json; charset=utf-8"]
            Alamofire.request(gplusapi, method: .get, parameters:nil, encoding: JSONEncoding.default, headers:header).responseData(completionHandler: { response -> Void in
                if response.result.isSuccess
                {
                    do {
                        let userData:NSDictionary = (try JSONSerialization.jsonObject(with: response.data!, options:[]) as? NSDictionary)!
                        var userDetails:UserInfo=UserInfo(firstName: "", lastName: "", dob: "", email: "", fullName: "", gender: "", accesstoken: "")
                        userDetails.firstName=GIDSignIn.sharedInstance().currentUser.profile.name
                        userDetails.email=GIDSignIn.sharedInstance().currentUser.profile.email
                    userDetails.accesstoken=GIDSignIn.sharedInstance().currentUser.authentication.idToken
                        if let error:NSDictionary = userData.object(forKey: "error") as? NSDictionary
                        {
                            self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:(error.object(forKey: "message") as? String)!)))
                            return
                        }
                        if let userGender = userData.object(forKey: "gender") as? String
                        {
                            
                        }
                        if let userAge = userData.object(forKey: "birthday") as? String {
                            let ageComponents = userAge.components(separatedBy: "-")
                            let dateDOB = Calendar.current.date(from: DateComponents(year:
                                Int(ageComponents[0]), month: Int(ageComponents[1]), day:
                                Int(ageComponents[2])))!
                        }
                        
                    } catch {
                        self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:error.localizedDescription)))
                    }
                }
                else
                {
                    self.showError(error: APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:error.localizedDescription)))

                }
            })
            
        }
    }
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        self.delegate?.errorRecieved(error:APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:(error?.localizedDescription)!)))

    }
    private func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: Error!)
    {
        self.delegate?.errorRecieved(error:APIError(status: false, error: APIError.ErrorDetail(errorCode: 0, errorType: .AlertMessage, displayMessage:(error?.localizedDescription)!)))
    }
    
}


