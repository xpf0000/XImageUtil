//
//  XImageGif.swift
//  XNetImage
//
//  Created by X on 16/3/11.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit
import ImageIO

let gifProperties=[kCGImagePropertyGIFDictionary as String:[kCGImagePropertyGIFLoopCount as String:0]]
class XImageGifPool: NSObject {
    
    static let Share = XImageGifPool()
    
    lazy var caches:[Int:XImageGifDict] = [:]
    
    var GifRunLoop:NSRunLoop?
    var thread:NSThread!
    
    private override init() {
        super.init()
        
        thread = NSThread(target: self, selector: #selector(XImageGifPool.newThread), object: nil)
        thread.start()
        
    }
    
    func newThread()
    {
        autoreleasepool
        {
            GifRunLoop = NSRunLoop.currentRunLoop()
            
            GifRunLoop?.addPort(NSMachPort(), forMode: NSRunLoopCommonModes)
            
            GifRunLoop?.run()
        }
    }
    
    func createGif(hash:Int,data:NSData)->XImageGifDict
    {
        var gif:XImageGifDict!
        if let item = caches[hash]
        {
            gif = item
        }
        else
        {
            gif = XImageGifDict(data: data)
            gif.urlHash = hash
            caches[hash] = gif
        }
        
        return gif
    }
    
}


class XImageGifDict: NSObject {
    
    var gif:AnyObject?
    var count:Int=0
    var totalTime:NSTimeInterval?
    var urlHash:Int = 0
    
    init(data:NSData) {
        
        gif=CGImageSourceCreateWithData(data,gifProperties as CFDictionaryRef)
        count=CGImageSourceGetCount(gif! as! CGImageSource);
        
        let d=CGImageSourceCopyPropertiesAtIndex(gif! as! CGImageSource, 0, nil)! as CFDictionaryRef
        
        let dict = d as Dictionary
        
        let gifDict:Dictionary<String,NSObject>?=dict[kCGImagePropertyGIFDictionary as String] as? Dictionary
        
        if let dict = gifDict
        {
            totalTime=dict["UnclampedDelayTime"] as? NSTimeInterval
        }
        
    }
    
    deinit
    {
        print("\(#function) in \(#file.componentsSeparatedByString("/").last!.stringByReplacingOccurrencesOfString(".swift", withString: ""))")
        
        gif = nil
        totalTime = nil
    }
    
}

class XImageGifPlayer: NSObject {
    
    weak var imageView:UIImageView?
    private var timer:NSTimer?
    private var ind:Int=0
    private var gif:XImageGifDict!
    private var urlHash = 0
    
    init(hash:Int,data:NSData,img:UIImageView) {
        super.init()
        self.urlHash = hash
        self.imageView = img
        self.gif = XImageGifPool.Share.createGif(hash, data: data)
    }
    
    func newThread()
    {
        autoreleasepool
        {
            if self.gif.totalTime != nil
            {
                self.timer?.invalidate()
                self.timer = nil
                self.ind = 0

                self.timer = NSTimer(timeInterval: self.gif.totalTime!, target: self, selector: #selector(XImageGifPlayer.play), userInfo: nil, repeats: true)
                XImageGifPool.Share.GifRunLoop?.addTimer(self.timer!, forMode: NSRunLoopCommonModes)

            }
               
        }
    }
    
    func rePlay()
    {

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.newThread()

        })
   
    }
    
    func play()
    {
        if(gif != nil && self.imageView != nil)
        {
            if let hash = self.imageView?.url?.hash
            {
                if hash != self.urlHash
                {
                    self.stop()
                    return
                }
            }
            
            ind += 1
            ind = ind%gif.count;
            
            let ref=CGImageSourceCreateImageAtIndex(gif.gif! as! CGImageSource, ind, gifProperties)
            self.imageView?.layer.contents = ref
        }
        else
        {
            self.stop()
        }
        
    }
    
    func stop()
    {
        timer?.invalidate()
        timer = nil
        self.imageView = nil
        gif = nil
    }
    
    deinit
    {
        stop()
        
        print("\(#function) in \(#file.componentsSeparatedByString("/").last!.stringByReplacingOccurrencesOfString(".swift", withString: ""))")
    }
}
