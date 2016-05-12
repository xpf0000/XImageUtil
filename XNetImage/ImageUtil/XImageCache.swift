//
//  XImageCache.swift
//  chengshi
//
//  Created by X on 16/4/28.
//  Copyright © 2016年 XSwiftTemplate. All rights reserved.
//

import Foundation
import UIKit

var XImageCachedCount = 0

class XImageCache: NSCache {
    
    override func setObject(obj: AnyObject, forKey key: AnyObject, cost g: Int) {
        
        if XImageCachedCount >= totalCostLimit
        {
            NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
            
            XImageUtil.Share.memCache.removeAllObjects()
        }
        
        XImageCachedCount += g
        
        super.setObject(obj, forKey: key, cost: g)
        
    }
    

    override func removeAllObjects() {
        
        super.removeAllObjects()
        
        XImageCachedCount = 0

    }
    
    
}