//
//  SecondViewController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit

class ConfigureViewController: UIViewController, UITextFieldDelegate {
    
    var default_hostname = "127.0.0.1"
    var default_hostport = 8080
    var default_packnum  = 50
    var default_frequency = 50 // packnum should larger than freq
    
    @IBOutlet weak var hostname: UITextField!
    @IBOutlet weak var hostport: UITextField!
    @IBOutlet weak var packnumVelueLabel: UILabel!
    @IBOutlet weak var packNumSlider: UISlider!
    @IBOutlet weak var freqSlider: UISlider!
    @IBOutlet weak var freqValueLabel: UILabel!
    
    var tabBarCtrl: TabBarController!
    
    // MARK: URL predicate
    let URLRegEx = "^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])$" //服务器IP地址匹配格式，本格式来自网络
    let portRegEx = "^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]{1}|6553[0-5])$"; //服务器端口号匹配格式，本方式来自网络
    
    var urltest: NSPredicate!
    var porttest: NSPredicate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tabBarCtrl = self.tabBarController as TabBarController
        
        self.default_hostname = tabBarCtrl.server_ip
        self.default_hostport = tabBarCtrl.server_port
        self.default_packnum = tabBarCtrl.pack_num
        self.default_frequency = tabBarCtrl.updateFreq
        
        hostname.text = tabBarCtrl.server_ip
        hostport.text = "\(tabBarCtrl.server_port)"
        packnumVelueLabel.text = "\(tabBarCtrl.pack_num)"
        packNumSlider.value = Float(tabBarCtrl.pack_num)
        freqValueLabel.text = "\(tabBarCtrl.updateFreq)"
        freqSlider.value = Float(default_frequency)
        
        hostname.delegate = self
        hostport.delegate = self
        
        urltest = NSPredicate(format: "SELF MATCHES %@", URLRegEx)
        porttest = NSPredicate(format: "SELF MATCHES %@", portRegEx)
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

    // MARK: TextField Actions
    @IBAction func HostEditing(sender: UITextField) {
        if (urltest.evaluateWithObject(sender.text)) {
            sender.textColor = UIColor.blackColor()
        } else {
            sender.textColor = UIColor.redColor()
        }
    }
    
    @IBAction func HostEditEnd(sender: UITextField) {
        if (urltest.evaluateWithObject(sender.text)) {
            tabBarCtrl.server_ip = sender.text
        } else {
            var alert = UIAlertController(title: "Invalid IP", message: sender.text, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func PortEditing(sender: UITextField) {
        if (porttest.evaluateWithObject(sender.text)) {
            sender.textColor = UIColor.blackColor()
        } else {
            sender.textColor = UIColor.redColor()
        }
    }
    
    @IBAction func PortEditEnd(sender: UITextField) {
        if porttest.evaluateWithObject(sender.text) {
            if let p = sender.text.toInt() {
                tabBarCtrl.server_port = p
            }
        } else {
            var alert = UIAlertController(title: "Invalid port", message: sender.text, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    // pack num
    @IBAction func PackNumValueChg(sender: UISlider) {
        self.packnumVelueLabel.text = "\(Int(sender.value))"
    }
    @IBAction func PackNumTouchUpInside(sender: UISlider) {
        self.tabBarCtrl.pack_num = Int(sender.value)
        if Int(sender.value) < tabBarCtrl.updateFreq  {
            var alert = UIAlertController(title: "WARN", message: "Pack num is too low, it should higher than update frequency.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    // updae freq
    @IBAction func FreqValueChg(sender: UISlider) {
        self.freqValueLabel.text = "\(Int(sender.value))"
    }
    @IBAction func FreqTouchUpInside(sender: UISlider) {
        self.tabBarCtrl.updateFreq = Int(sender.value)
        if Int(sender.value) > tabBarCtrl.pack_num {
            var alert = UIAlertController(title: "WARN", message: "Update frequency is too high, which should lower than pack num.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
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
        freqValueLabel.text = "\(default_frequency)"
        freqSlider.value = Float(default_frequency)
        
        tabBarCtrl.server_ip = default_hostname
        tabBarCtrl.server_port = default_hostport
        tabBarCtrl.pack_num = default_packnum
        tabBarCtrl.updateFreq = default_frequency
    }
    var waitingConnect: Bool = false
    @IBAction func AutoConnectTapped(sender: UIButton) {
        var client:UDPClient=UDPClient(addr: "255.255.255.255", port: 8080)
        NSLog("send hello msg")
        var (success, msg) = client.send(str: "MOTION PORT") // TODO: send more useful data
        if !success {
            println("\(success): \(msg)")
        }
        client.close()
        if !waitingConnect {
            waitingConnect = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                // wating connection (echo)
                var server: UDPServer = UDPServer(addr: "0.0.0.0", port: 8081)
                var (data, rip, rport) = server.recv(1024)
                NSLog("received from IP:\(rip) port\(rport) \(data)") // TODO: configure IP with this data
                server.close()
                self.waitingConnect = false
            })
        }
    }

}

