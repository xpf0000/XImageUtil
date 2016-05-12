//
//  ViewController.swift
//  XNetImage
//
//  Created by X on 16/3/5.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var label: UILabel!
    
    
    @IBAction func cleanMCache(sender: AnyObject) {
        
        XImageUtil.removeAllMemCache()
    }
    
    @IBAction func cleanCache(sender: UIButton) {
        XImageUtil.removeAllFile()
        
        label.text = "0.00M"
    }
    
    @IBAction func userControll(sender: AnyObject) {
        
        XImageUtil.Share.autoDown = .None
    }
    
    @IBAction func auto(sender: AnyObject) {
        
        XImageUtil.Share.autoDown = .All
    }
    
    
    @IBAction func wifi(sender: AnyObject) {
        
        XImageUtil.Share.autoDown = .WiFi
    }
    
    @IBAction func mobil(sender: AnyObject) {
        
        XImageUtil.Share.autoDown = .WWAN
    }
    
    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        label.text = String(format: "%.2fM", XImageUtil.ImageCachesSize()/1024.0/1024.0)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }


}

