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

class MainViewController: UIViewController {

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
        println("set ip as \(serverIP):\(port) pack num: \(tabBarCtrl.pack_num) freq: \(tabBarCtrl.updateFreq)")
        
        tabBarCtrl.clientClosed = true
//        openUDP()
//        startMotionUpdate(20)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.closeUDP()
        motionManager.stopDeviceMotionUpdates()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: UDP
    var client: UDPClient!
    var serverIP:String = "localhost"
    var port: Int = 8888
    var udpData: [Float] = []
    // MARK: pack include (timestamp, ax, ay, az)
    let packSize = 4 // the number of parameter in a pack
                     // for example 3 for (ax, ay, az)
    // temp saved msg
    var packCount = 0
    var indexForUDP: Int32 = 0

    func openUDP() -> Bool {
        client = UDPClient(addr: self.serverIP, port: self.port)
        tabBarCtrl.clientClosed = false
        NSLog("open UDP")
        if startMotionUpdate(updateFrequency: tabBarCtrl.updateFreq) {
            // TODO: add a button to start the update. If not updating do not open the udp!
            NSLog("start motion update")
        } else {
            client.close()
            tabBarCtrl.clientClosed = true
            var alert = UIAlertController(title: "", message: "The Device Motion can not be started", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        return !tabBarCtrl.clientClosed
    }
    
    func closeUDP() -> Bool {
        if tabBarCtrl.clientClosed {
            return tabBarCtrl.clientClosed
        }
//        motionManager.stopDeviceMotionUpdates()
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
    
    func startMotionUpdate(updateFrequency freq: Int) -> Bool {
        let delta: NSTimeInterval = 0.005
        let UpdateInterval: NSTimeInterval = 1 / Double(freq) //accelerometerMin + delta * Double(slideValue)
        if UpdateInterval < accelerometerMin {
            // TODO: Determine the real update interval of the hardware
            println("WARN: update frequency is too high: \(UpdateInterval) (max frequency is 100Hz)")
        }
        
        if motionManager.deviceMotionAvailable {
            if !motionManager.magnetometerAvailable {
                println("magnetic not avaliable")
            } else if (CMMotionManager.availableAttitudeReferenceFrames() & Int(CMAttitudeReferenceFrameXTrueNorthZVertical.value)) == 0 {
                    println("CMAttitudeReferenceFrameXArbitraryZVertical not ok")
            }
            motionManager.deviceMotionUpdateInterval = UpdateInterval
            motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrameXTrueNorthZVertical, toQueue: NSOperationQueue.currentQueue(), withHandler: {
                // Device Motion Block
                (dm: CMDeviceMotion!,  error:NSError!) in
                if let deviceMotion = dm {
                    if self.start_timestamp == 0 {
                        self.start_timestamp = deviceMotion.timestamp // MARK: set start timestamp
                    }
                    
                    self.timestamp = deviceMotion.timestamp - self.start_timestamp
    //                println("timestamp \(self.timestamp)")
                    
                    // raw user accellerate
//                    self.ax = deviceMotion.userAcceleration.x * 9.81
//                    self.ay = deviceMotion.userAcceleration.y * 9.81
//                    self.az = deviceMotion.userAcceleration.z * 9.81
                    
                    // user accellerate respect to the world
//                    var acc: CMAcceleration = deviceMotion.gravity
                    var acc: CMAcceleration = deviceMotion.userAcceleration
                    var rot = deviceMotion.attitude.rotationMatrix
                    self.ax = (acc.x*rot.m11 + acc.y*rot.m21 + acc.z*rot.m31)*9.81
                    self.ay = (acc.x*rot.m12 + acc.y*rot.m22 + acc.z*rot.m32)*9.81
                    self.az = (acc.x*rot.m13 + acc.y*rot.m23 + acc.z*rot.m33)*9.81
                    
                    // raw gravity
//                    self.ax = deviceMotion.gravity.x
//                    self.ay = deviceMotion.gravity.y
//                    self.az = deviceMotion.gravity.z
                    
                    // attitude
//                    self.ax = deviceMotion.attitude.roll
//                    self.ay = deviceMotion.attitude.pitch
//                    self.az = deviceMotion.attitude.yaw
                    
                    if !self.tabBarCtrl.clientClosed {
                        self.sendDataPack(/*requiredPackCount: self.tabBarCtrl.pack_num*/) //self.defaultPackNum)
                    }
                    
//                    if deviceMotion.magneticField.accuracy.value == -1 {
////                        println("magnetic field not valid")
////                        println("\(deviceMotion.magneticField.field.x)")
//                    }

                }
            })
            return true
        } else {
            NSLog("device motion is not available")
            return false
        }
    }
    
    func sendDataPack(/*requiredPackNum len: Int*/) -> Bool {
        if udpData.count == self.tabBarCtrl.pack_num * packSize {
            self.packCount = self.dataIndex / self.tabBarCtrl.pack_num
            indexForUDP = Int32(dataIndex)
            /* prepare for ending data */
            var dtCount = Int32(self.udpData.count)
            let dt: NSData = NSData(bytes: self.udpData, length: sizeof(Float)*self.udpData.count)
            self.cleanUDPData()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                () -> Void in
                //                    let dataStr = "ax:\(self.ax);ay:\(self.ay);az:\(self.az)"
                var success = false
                var msg = ""
                /* send the last index of the pack */
                (success, msg) = self.client.send(data: NSData(bytes: &self.indexForUDP, length: sizeof(Int32)))
                if !success {
                    println("send index failed: \(msg)")
//                    if msg == "socket not open" {
                        self.closeUDP()
                    var alertCtrl = UIAlertController(title: "Send data FAILED", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                    var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                    alertCtrl.addAction(okAction)
                    self.presentViewController(alertCtrl, animated: true, completion: nil)
//                    }
                    return
                }
                /* send size of data */
                (success, msg) = self.client.send(data: NSData(bytes: &dtCount, length: sizeof(Int32)))//[UInt8(self.udpData.count)])
                if !success {
                    println("send data size failed: \(msg)")
                    return
                }
                /* send data */
                (success, msg) = self.client.send(data: dt)
                if success {
//                    self.AttributeTable.setNeedsDisplay() // Update Table View
                    dispatch_async(dispatch_get_main_queue(), {self.AttributeTable.reloadData()})
                }
            })
        } else if udpData.count < self.tabBarCtrl.pack_num * packSize {
            udpData.append(Float(timestamp)) // send timestamp
            udpData.append(Float(ax))
            udpData.append(Float(ay))
            udpData.append(Float(az))
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
        if udpData.count > 0 {
            self.udpData.removeAll(keepCapacity: true)
        }
    }

    @IBAction func UDPSwitchTapped(sender: AnyObject) {
        let but = sender as UIButton
        if tabBarCtrl.clientClosed {
            if (openUDP()) {
                but.setTitle("Close", forState: .Normal)
            }
        } else {
            closeUDP()
        }
    }
    
}

// MARK: Tabele View Data Source
extension MainViewController: UITableViewDataSource {
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

