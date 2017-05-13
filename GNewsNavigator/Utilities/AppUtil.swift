//
//  AppUtil.swift
//  GNewsNavigator
//
//  Created by venus.janne on 15-12-27.
//  Copyright © 2015 venus.janne. All rights reserved.
//

import UIKit

class AppUtil: NSObject {

    class func showInfoView(_ sender: UIViewController, message msg:String, caption title:String){
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)

        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "OK", style: .default) { action in
            print("Action OK!!")
        }
        
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)

        // UIAlertを発動する.
        sender.present(myAlert, animated: true, completion: nil)
    }
}
