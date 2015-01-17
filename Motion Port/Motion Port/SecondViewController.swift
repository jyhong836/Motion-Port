//
//  SecondViewController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var hostname: UITextField!
    @IBOutlet weak var hostport: UITextField!
    
    var tabBarCtrl: TabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tabBarCtrl = self.tabBarController as TabBarController
        hostname.text = tabBarCtrl.server_ip
        hostport.text = "\(tabBarCtrl.server_port)"
        
        hostname.delegate = self
        hostport.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        hostname.resignFirstResponder()
        hostport.resignFirstResponder()
    }

    @IBAction func HostEditEnd(sender: UITextField) {
        if (isCorrectIP(sender.text)) {
            tabBarCtrl.server_ip = sender.text
        }
    }
    
    @IBAction func PortEditEnd(sender: UITextField) {
        tabBarCtrl.server_port = sender.text.toInt()!
    }
    
    func isCorrectIP(ip: String) -> Bool {
        // TODO: check if is correct ip
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

