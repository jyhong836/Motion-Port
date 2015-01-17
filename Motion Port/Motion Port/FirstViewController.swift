//
//  FirstViewController.swift
//  Motion Port
//
//  Created by Junyuan Hong on 15/1/17.
//  Copyright (c) 2015年 Junyuan Hong. All rights reserved.
//

import UIKit
import CoreMotion

class FirstViewController: UIViewController {

    @IBOutlet weak var AttributeTable: UITableView!
    
    let accelerometerMin: NSTimeInterval = 0.01
    var motionManager = CMMotionManager()
    
    var dataIndex:Int = 0
    var ax: Double = 0.0
    var ay: Double = 0.0
    var az: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AttributeTable.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        openUDP()
        startMotionUpdate(20)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.closeUDP()
    }
    
    // MARK: UDP
    var client: UDPClient!
    var serverIP:String = "192.168.2.138"
    var port: Int = 8080
    var clientClosed = false
    var udpData: [Double] = []
    let packSize = 3 // the number of parameter in a pack
                     // for example 3 for (ax, ay, az)
    let defaultPackNum = 20
    // temp saved msg
    var packCount = 0
    var indexForUDP: Int32 = 0

    func openUDP() {
        client = UDPClient(addr: self.serverIP, port: self.port)
        clientClosed = false
        NSLog("open UDP")
    }
    
    func closeUDP() -> Bool {
        var success = false
        var msg = ""
        var i: Int32 = -1
        (success, msg) = self.client.send(data: NSData(bytes: &i, length: sizeof(Int32)))
        if !success {
            println("send 'Exit' failed: \(msg)")
        }
        (clientClosed, msg) = client.close()
        if !clientClosed {
            println("close UDP failed: \(msg)")
        } else {
            NSLog("close UDP success")
        }
        return clientClosed
    }
    
    
    func startMotionUpdate(slideValue: Int) {
        let delta: NSTimeInterval = 0.005
        let UpdateInterval: NSTimeInterval = accelerometerMin + delta * Double(slideValue)
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = UpdateInterval
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: {
                (deviceMotion: CMDeviceMotion!,  error:NSError!) in
                self.ax = deviceMotion.userAcceleration.x
                self.ay = deviceMotion.userAcceleration.y
                self.az = deviceMotion.userAcceleration.z
                
                if !self.clientClosed {
                    self.sendDataPack(requiredLength: self.defaultPackNum)
                }
                
//                dispatch_async(dispatch_get_main_queue(), {
//                    () -> Void in
//                    self.CountLabel.text = "[\(self.dataIndex)] port: \(self.port)"
//                    self.value1.text = NSString(format: "x: %3.2f cm/s2", self.ax*100)
//                    self.value2.text = NSString(format: "y: %3.2f cm/s2", self.ay*100)
//                    self.value3.text = NSString(format: "z: %3.2f cm/s2", self.az*100)
//                    self.AttributeTable.setNeedsDisplay()
//                })
            })
        } else {
            NSLog("device motion is not available")
        }
    }
    
    func sendDataPack(requiredLength len: Int) -> Bool {
        if udpData.count == len * packSize {
            self.packCount = self.dataIndex / self.defaultPackNum
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
        } else if udpData.count < len * packSize {
            udpData.append(ax)
            udpData.append(ay)
            udpData.append(az)
//            println("[\(self.dataIndex).\(udpData.count/packSize)/\(len)] store x \(self.ax) y \(self.ay) z \(self.az)")
            self.dataIndex++
        } else if udpData.count > len * packSize {
            println("Data is out of pack size for Unkonwn Reason! Clen them!")
            cleanUDPData()
            return false
        }
        return true
    }
    
    func cleanUDPData() {
        udpData.removeAll(keepCapacity: true)
    }

    @IBAction func UDPSwitchTapped(sender: AnyObject) {
        let but = sender as UIButton
        if clientClosed {
            openUDP()
            but.setTitle("Close", forState: .Normal)
        } else {
            if closeUDP() {
                but.setTitle("Open ", forState: .Normal)
            }
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
                cell!.valueText.text = NSString(format: "%3.2lf", ax*100)
            case 2:
                cell!.title.text = "y"
                cell!.valueText.text = NSString(format: "%3.2lf", ay*100)
            case 3:
                cell!.title.text = "z"
                cell!.valueText.text = NSString(format: "%3.2lf", az*100)
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

