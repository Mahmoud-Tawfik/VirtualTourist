
//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/17/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Stack.autoSave(delayInSeconds: 60)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Stack.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Stack.saveContext()
    }

}

