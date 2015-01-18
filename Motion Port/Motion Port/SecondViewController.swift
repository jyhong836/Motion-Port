//
//  SecondViewController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITextFieldDelegate {
    
    let default_hostname = "127.0.0.1"
    let default_hostport = 8080
    let default_packnum  = 10
    
    @IBOutlet weak var hostname: UITextField!
    @IBOutlet weak var hostport: UITextField!
    @IBOutlet weak var packnumVelueLabel: UILabel!
    @IBOutlet weak var packNumSlider: UISlider!
    
    var tabBarCtrl: TabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tabBarCtrl = self.tabBarController as TabBarController
        hostname.text = tabBarCtrl.server_ip
        hostport.text = "\(tabBarCtrl.server_port)"
        packnumVelueLabel.text = "\(tabBarCtrl.pack_num)"
        
        hostname.delegate = self
        hostport.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // TODO: save configure data to Core Data
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
        if let p = sender.text.toInt() {
            tabBarCtrl.server_port = p
        }
    }
    
    @IBAction func PackNumValueChg(sender: UISlider) {
        self.packnumVelueLabel.text = "\(Int(sender.value))"
        self.tabBarCtrl.pack_num = Int(sender.value)
    }
    
    func isCorrectIP(ip: String) -> Bool {
        // TODO: check if is correct ip
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func ResetTapped(sender: UIButton) {
        hostname.text = default_hostname
        hostport.text = "\(default_hostport)"
        packnumVelueLabel.text = "\(default_packnum)"
        packNumSlider.value = Float(default_packnum)
        
        tabBarCtrl.server_ip = default_hostname
        tabBarCtrl.server_port = default_hostport
        tabBarCtrl.pack_num = default_packnum
    }

}

