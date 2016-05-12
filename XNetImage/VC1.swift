//
//  VC1.swift
//  XNetImage
//
//  Created by X on 16/3/7.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit

class VC1: UIViewController {

    
    @IBOutlet var image: UIImageView!
    
    @IBOutlet var image1: UIImageView!
    
    @IBOutlet var image2: UIImageView!
    
    @IBOutlet var image3: UIImageView!
    
    @IBOutlet var image4: UIImageView!
    
    @IBOutlet var image5: UIImageView!
    
    
    
    
    //let image = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = "http://p1.pichost.me/i/40/1639665.png"
        
        
        let s = "http://a.hiphotos.baidu.com/baike/c0%3Dbaike272%2C5%2C5%2C272%2C90/sign=938219ef8f1001e95a311c5dd9671089/95eef01f3a292df5d0b0fc13be315c6034a87340.jpg"
        
        let s1 = "http://img1.imgtn.bdimg.com/it/u=381107085,1683754138&fm=21&gp=0.jpg"
        
        let s3 = "http://p1.pichost.me/i/40/1639665.png"
        

        let s5 = "http://img0.imgtn.bdimg.com/it/u=2338566287,3339538133&fm=21&gp=0.jpg"
        
        let s2 = "http://image.tianjimedia.com/uploadImages/2013/171/BUA9M62YPM9D.jpg"
        
        let s4 = "http://image63.360doc.com/DownloadImg/2013/08/0615/34309668_19.jpg"
        
        let s6 = "http://mg.soupingguo.com/bizhi/big/10/369/268/10369268.jpg"
        
        let s7 = "http://img5.imgtn.bdimg.com/it/u=490355224,2723139031&fm=21&gp=0.jpg"
        
        let s8 = "http://img.zcool.cn/community/01c2ed55ee45cb6ac7251df85c42df.gif"
        
        
        image.placeholder = UIImage(named: "143131944.jpg")
        //image2.placeholder = UIImage(named: "143131944.jpg")
        image3.placeholder = UIImage(named: "143131944.jpg")
        
        image.url = s5
        
        image1.url = s4
        
        image2.url = s3
        
        image3.url = s8
        
        image4.url = s7
        
        image5.url = s6
        
        image2.isGroup = true
        image3.isGroup = true
        image4.isGroup = true
        image5.isGroup = true
        
        image.contentMode = .Bottom
        
        image1.contentMode = .BottomLeft
        
        image.isGroup = true
        image1.isGroup = true
        
        //XImageUtil.Share.createTask(s2).startDownLoad()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    deinit
    {
        print("vc1 deinit !!!!!!!")
        
        //print(testD)
        //testD = nil
    }

}
