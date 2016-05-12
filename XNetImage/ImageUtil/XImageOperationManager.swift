//
//  XImageOperationManager.swift
//  chengshi
//
//  Created by X on 16/4/20.
//  Copyright © 2016年 XSwiftTemplate. All rights reserved.
//

import Foundation
import UIKit

class XOperationQueue: NSOperationQueue {
    
    override func addOperation(op: NSOperation) {
        
        super.addOperation(op)
        
        let out = operations.count - maxConcurrentOperationCount
        
        if out <= 0 {return}
        
        for i in 0..<out
        {
            operations[i].cancel()
        }
    }
    
}

class XImageOperationManager:NSObject {
    
    static let Share = XImageOperationManager()
    var operation:XOperationQueue! = XOperationQueue()
    
    var lastOperation:NSOperation?

    
    private override init() {
        super.init()
        
        operation.maxConcurrentOperationCount = 10

    }

    
    
}