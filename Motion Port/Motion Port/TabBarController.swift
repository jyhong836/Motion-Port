//
//  TabBarController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController/*, UITabBarControllerDelegate*/ {
    
    var arch = NSUserDefaults.standardUserDefaults()
    
    // global configures
    var server_ip = "192.168.1.8"// "192.168.2.138"
    var server_port = 8080
    var pack_num = 50
    var updateFreq = 50
    
    var clientClosed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func storeConfigure() {
        arch.setObject(server_ip, forKey: "server_ip")
        arch.setInteger(server_port, forKey: "server_port")
        arch.setInteger(pack_num, forKey: "pack_num")
        arch.setInteger(updateFreq, forKey: "updateFreq")
    }
    
    func loadConfigure() {
        if let obj: AnyObject = arch.objectForKey("server_ip") {
            server_ip = obj as String
        } else {
            return
        }
        server_port = arch.integerForKey("server_port")
        pack_num = arch.integerForKey("pack_num")
        updateFreq = arch.integerForKey("updateFreq")
    }
    
//    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
//        println("selected \(viewController)")
//    }
    

}
