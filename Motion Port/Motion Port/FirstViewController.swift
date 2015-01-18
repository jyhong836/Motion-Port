//
//  FirstViewController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit
import CoreMotion
import SystemConfiguration

class FirstViewController: UIViewController {

    @IBOutlet weak var AttributeTable: UITableView!
    @IBOutlet weak var UDPSwitchBut: UIButton!
    
    let accelerometerMin: NSTimeInterval = 0.01
    var motionManager = CMMotionManager()
    
    var dataIndex:Int = 0
    var start_timestamp: Double = 0
    var timestamp: Double = 0
    var ax: Double = 0.0
    var ay: Double = 0.0
    var az: Double = 0.0
    
    var tabBarCtrl: TabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tabBarCtrl = self.tabBarController as TabBarController
        
        AttributeTable.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.serverIP = tabBarCtrl.server_ip
        self.port = tabBarCtrl.server_port
        println("set ip as \(serverIP):\(port) pack num: \(tabBarCtrl.pack_num)")
        
        tabBarCtrl.clientClosed = true
//        openUDP()
//        startMotionUpdate(20)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.closeUDP()
    }
    
    // MARK: UDP
    var client: UDPClient!
    var serverIP:String = "localhost"
    var port: Int = 8888
//    var clientClosed = false
    var udpData: [Double] = []
    let packSize = 3 // the number of parameter in a pack
                     // for example 3 for (ax, ay, az)
//    let defaultPackNum = 20
    // temp saved msg
    var packCount = 0
    var indexForUDP: Int32 = 0

    func openUDP() {
        client = UDPClient(addr: self.serverIP, port: self.port)
        tabBarCtrl.clientClosed = false
        NSLog("open UDP")
        startMotionUpdate(updateFrequency: 20)
        // TODO: add a button to start the update. If not updating do not open the udp!
        NSLog("start motion update")
    }
    
    func closeUDP() -> Bool {
        if tabBarCtrl.clientClosed {
            return tabBarCtrl.clientClosed
        }
        var success = false
        var msg = ""
        var i: Int32 = -1
        (success, msg) = self.client.send(data: NSData(bytes: &i, length: sizeof(Int32)))
        if !success {
            println("send 'Exit' failed: \(msg)")
        }
        
        (tabBarCtrl.clientClosed, msg) = client.close()
        if !tabBarCtrl.clientClosed {
            println("close UDP failed: \(msg)")
        } else {
            NSLog("close UDP success")
            dispatch_async(dispatch_get_main_queue(), {self.UDPSwitchBut.setTitle("Open", forState: .Normal)})
        }
        
        return tabBarCtrl.clientClosed
    }
    
    
    func startMotionUpdate(updateFrequency freq: Int) {
        let delta: NSTimeInterval = 0.005
        let UpdateInterval: NSTimeInterval = 1 / Double(freq) //accelerometerMin + delta * Double(slideValue)
        if UpdateInterval < accelerometerMin {
            // TODO: Determine the real update interval of the hardware
            println("WARN: update interval is too short: \(UpdateInterval) (max frequency is 100Hz)")
        }
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = UpdateInterval
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: {
                // Device Motion Block
                (deviceMotion: CMDeviceMotion!,  error:NSError!) in
                if self.start_timestamp == 0 {
                    self.start_timestamp = deviceMotion.timestamp // MARK: set start timestamp
                }
                
                self.timestamp = deviceMotion.timestamp - self.start_timestamp
//                println("timestamp \(self.timestamp)")
                
                self.ax = deviceMotion.userAcceleration.x
                self.ay = deviceMotion.userAcceleration.y
                self.az = deviceMotion.userAcceleration.z
                
                if !self.tabBarCtrl.clientClosed {
                    self.sendDataPack(/*requiredPackCount: self.tabBarCtrl.pack_num*/) //self.defaultPackNum)
                }
            })
        } else {
            NSLog("device motion is not available")
        }
    }
    
    func sendDataPack(/*requiredPackNum len: Int*/) -> Bool {
        if udpData.count == self.tabBarCtrl.pack_num * packSize {
            self.packCount = self.dataIndex / self.tabBarCtrl.pack_num
            indexForUDP = Int32(dataIndex)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                () -> Void in
                //                    let dataStr = "ax:\(self.ax);ay:\(self.ay);az:\(self.az)"
                var success = false
                var msg = ""
                /* send the last index of the pack */
                (success, msg) = self.client.send(data: NSData(bytes: &self.indexForUDP, length: sizeof(Int32))) // TODO: need to change in matlab
                if !success {
                    println("send index failed: \(msg)")
//                    if msg == "socket not open" {
                        self.closeUDP()
//                    }
                    return
                }
                /* send size of data */
                (success, msg) = self.client.send(data: [UInt8(self.udpData.count)])
                if !success {
                    println("send data size failed: \(msg)")
                    return
                }
                /* send data */
                let udpData: NSData = NSData(bytes: self.udpData, length: sizeof(Double)*self.udpData.count)
                
                (success, msg) = self.client.send(data: udpData)
                if success {
                    self.cleanUDPData()
//                    self.AttributeTable.setNeedsDisplay() // Update Table View
                    dispatch_async(dispatch_get_main_queue(), {self.AttributeTable.reloadData()})
                }
            })
        } else if udpData.count < self.tabBarCtrl.pack_num * packSize {
            udpData.append(ax)
            udpData.append(ay)
            udpData.append(az)
//            println("[\(self.dataIndex).\(udpData.count/packSize)/\(len)] store x \(self.ax) y \(self.ay) z \(self.az)")
            self.dataIndex++
        } else /*if udpData.count > self.tabBarCtrl.pack_num * packSize*/ {
            println("Data is out of pack size for Unkonwn Reason! Clen them!")
            cleanUDPData()
            return false
        }
        return true
    }
    
    func cleanUDPData() {
        self.udpData.removeAll(keepCapacity: true)
    }

    @IBAction func UDPSwitchTapped(sender: AnyObject) {
        let but = sender as UIButton
        if tabBarCtrl.clientClosed {
            openUDP()
            but.setTitle("Close", forState: .Normal)
        } else {
            closeUDP()
        }
    }
    
}

// MARK: Tabele View Data Source
extension FirstViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row >= 1 {
            var cellName = "xValueCell"
            var cell = tableView.dequeueReusableCellWithIdentifier(cellName) as xValueTableViewCell?
            
            switch(indexPath.row) {
            case 1:
                cell!.title.text = "x"
                cell!.valueText.text = NSString(format: "%5.4lf", ax*100)
            case 2:
                cell!.title.text = "y"
                cell!.valueText.text = NSString(format: "%5.4lf", ay*100)
            case 3:
                cell!.title.text = "z"
                cell!.valueText.text = NSString(format: "%5.4lf", az*100)
            default:
                break
            }
            
            return cell!
        } else {
            var cellName = "MsgCell"
            var cell = tableView.dequeueReusableCellWithIdentifier(cellName) as UITableViewCell?
            
            cell!.textLabel!.text = "Pack Count \(packCount)"
            
            return cell!
        }
    }
    
}

