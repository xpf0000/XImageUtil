//
//  XImageDownLoader.swift
//  XNetImage
//
//  Created by X on 16/3/8.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit
import ImageIO

class XImageDownLoader: NSOperation {
    
    var data:NSMutableData?
    var url = ""
    var task:NSURLSessionDataTask?
    
    var immediately = true
    var progress:[XImgProgressModel] = []
    var complete:[XImgCompleteModel] = []
    
    var ended = false
    var quxiao = false
    var taskRunning = false
    var selfRunning = false
    
    weak var view:UIImageView?
    
    var key:String
    {
        let size = view?.bounds.size
        if size == nil
        {
            return "\(self.url.hash)"
        }
        else
        {
            return "\(self.url.hash)\(Int(size!.width))\(Int(size!.height))"
        }
        
    }
    
    override var cancelled: Bool
        {
        get
        {
            return quxiao
        }
    }
    
    override var executing: Bool
        {
        get
        {
            return selfRunning
        }
    }
    
    override var finished: Bool
        {
        get
        {
            return ended
        }
    }
    
    override var asynchronous: Bool
        {
        get
        {
            return true
        }
    }
    
    func doCancell()
    {
        self.willChangeValueForKey("isCancelled")
        quxiao = true
        self.didChangeValueForKey("isCancelled")
    }
    
    func doFinish()
    {
        self.willChangeValueForKey("isFinished")
        ended = true
        self.didChangeValueForKey("isFinished")
    }
    
    override func cancel() {
        
        if task?.state != .Completed
        {
            task?.cancel()
        }
        
        doCancell()
        doFinish()
 
    }
    
    func destroy()
    {
        XImageUtil.Share.removeTask(url.hash)
        self.view = nil
        self.taskRunning = false
        self.progress.removeAll(keepCapacity: false)
        self.complete.removeAll(keepCapacity: false)
        self.task?.cancel()
        self.task = nil
        self.data = nil
    }
    
    
    override func start() {
        
        autoreleasepool {
            
            if self.cancelled{
                
                doFinish()
                return
                
            }
            
            self.willChangeValueForKey("isExecuting")
            selfRunning = true
            self.didChangeValueForKey("isExecuting")
            
            self.createTask()
            
        }
        
        
    }
    
    
    var savePath:String
        {
            return (XImageSavePath as NSString).stringByAppendingPathComponent("\(url.hash)")
    }

    func createTask()
    {
        if self.taskRunning || self.task != nil || self.url == "" || self.quxiao
        {
            return
        }
        
        let savePath = (XImageSavePath as NSString).stringByAppendingPathComponent("\(self.url.hash)")
        
        if XImageUtil.Share.memCache.objectForKey(key) != nil || XImageUtil.FileManager.fileExistsAtPath(savePath)
        {
            self.taskRunning = true
            
            var image:UIImage?
            var data:NSData?
            
            if let obj = XImageUtil.Share.memCache.objectForKey(key)
            {
                if obj is UIImage
                {
                    image = obj as? UIImage
                }
                else if obj is NSData
                {
                    data = obj as? NSData
                    image = UIImage(data: data!)
                }
            }
            else
            {
                if self.quxiao
                {
                    return
                }
                
                if let d =  NSData(contentsOfFile: savePath)
                {
                    (image,data) = self.handleData(d)
                }
                
            }
            
            self.downComplete(image, data: data)
            
            return
        }
        
        let r = NSMutableURLRequest(URL: NSURL(string: self.url)!)
        r.timeoutInterval = 0
        
        self.task = XImageUtil.Share.session.dataTaskWithRequest(r)
        
        if #available(iOS 8.0, *) {
            
            self.task?.priority = 1.0
   
        } else {
            // Fallback on earlier versions
        }
        self.taskRunning = false
        
        if self.immediately
        {
            self.startDownLoad()
        }
        else
        {
            self.doFinish()
        }
        
        return
        
    }
    
    
    func startDownLoad()
    {
        if self.task == nil {return}
        
        if self.task?.state != .Completed && self.task?.state != .Running && self.task?.state != .Canceling
        {
            self.task?.resume()
            self.taskRunning = true
        }
        else
        {
            let received = self.task?.countOfBytesReceived
            let count = self.task?.countOfBytesExpectedToReceive
            
            if received != nil && count != nil && count > 0
            {
                self.sendProgress(CGFloat(received!)/CGFloat(count!))
            }
        }
    }
    
    func saveFile(error: NSError?)->(UIImage?,NSData?)
    {
        if error != nil || self.data == nil {return (nil,nil)}
        
        autoreleasepool {
            
            self.data?.writeToFile(savePath, atomically: false)
  
        }
        
        return handleData(self.data!)
        
    }

    private func handleData(d:NSData)->(UIImage?,NSData?)
    {
        var image:UIImage?
        var data:NSData?
        var saveObj:AnyObject?
        
        let size = view?.bounds.size
        
        let b = XImageUtil.Share.memCache.objectForKey(key) == nil
        
        let type = ImageTypeForData(d)
        
        if type == .GIF
        {
            saveObj = d
            data = d
            image = UIImage(data: d)
        }
        else if type == .WEBP
        {
            image = DecodedImage(UIImage(webPData: d),size: size)
            saveObj = image
        }
        else
        {
            if self.quxiao
            {
                return (nil,nil)
            }
            
            image = DecodedImage(UIImage(data: d),size: size)
            saveObj = image
        }
        
        if b && saveObj != nil
        {
            XImageUtil.Share.memCache.setObject(saveObj!, forKey: key, cost: d.length)
        }
        
        return (image,data)
    }
    
    func sendProgress(p:CGFloat)
    {
        autoreleasepool { () -> () in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                for item in self.progress
                {
                    item.block?(self.url,p)
                }
                
            })
            
        }
        
    }
    
    func downComplete(image:UIImage?,data:NSData?)
    {
        autoreleasepool { () -> () in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                for item in self.complete
                {
                    item.block?(self.url,image,data)
                }
                self.doFinish()
                self.destroy()
                
            })
            
        }
    }
    
    deinit
    {
        self.destroy()
        
        print("\(#function) in \(#file.componentsSeparatedByString("/").last!.stringByReplacingOccurrencesOfString(".swift", withString: "")) | \(self)")
        
    }
    
}