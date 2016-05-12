//
//  ImageCache.swift
//  OA
//
//  Created by X on 15/8/27.
//  Copyright (c) 2015年 OA. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

typealias XImageProgressBlock = (String,CGFloat)->Void
typealias XImageCompleteBlock = (String,UIImage?,NSData?)->Void

@objc
enum AutoDownLoadType: Int {
    
    case None
    case WWAN
    case WiFi
    case All
    
}

@objc
enum ImageContentType: Int {
    case None
    case JPEG
    case PNG
    case GIF
    case TIFF
    case WEBP
}

func ImageTypeForData(data:NSData)->ImageContentType
{
    var c:Int = 0
    data.getBytes(&c, length: 1)
    
    switch (c) {
    case 0xFF:
        return .JPEG;
    case 0x89:
        return .PNG;
    case 0x47:
        return .GIF;
    case 0x49,0x4D:
        return .TIFF;
    case 0x52:
        // R as RIFF for WEBP
        if (data.length < 12) {
            return .None;
        }
        
        if let testString = NSString(data: data.subdataWithRange(NSMakeRange(0, 12)), encoding: NSASCIIStringEncoding)
        {
            if testString.hasPrefix("RIFF") && testString.hasPrefix("WEBP")
            {
                return .WEBP;
            }
        }
        
    default:
        ""
        return .None;
    }
    
    return .None;
}

func DecodedImage(image:UIImage?,size:CGSize?)->UIImage?
{
    if (image == nil || image?.images?.count > 0) {return image}
    //var img:UIImage?

    let screenScale=UIScreen.mainScreen().scale
    let swidth=UIScreen.mainScreen().bounds.size.width
    let sheight=UIScreen.mainScreen().bounds.size.height
    
    let imgw = image!.size.width
    let imgh = image!.size.height
    
    var width = size == nil ? swidth : size!.width
    var height = size == nil ? sheight : size!.height
    
    width = width == 0 ? swidth : width
    height = height == 0 ? sheight : height
    
    if imgw / imgh > width / height
    {
        if imgh > height*screenScale
        {
            height=height*screenScale
            
            width = imgw / imgh * height
        }
        else
        {
            width = imgw
            height = imgh
        }

    }
    else
    {
        if imgw > width*screenScale
        {
            width = width*screenScale
            height = imgh / imgw * width
        }
        else
        {
            width = imgw
            height = imgh
        }
    }
    
    //return image?.scaledToSize(CGSizeMake(width, height))
    
    //let image = image?.scaledToSize(CGSizeMake(width, height))

    let imageRef = image!.CGImage;
    
    let alpha = CGImageGetAlphaInfo(imageRef);
    let anyAlpha = (alpha == .First ||
        alpha == .Last ||
        alpha == .PremultipliedFirst ||
        alpha == .PremultipliedLast);
    
    if (anyAlpha) {
        
        return image?.scaledToSize(CGSizeMake(width, height))
        
    }
    
    
    var imageWithAlpha:UIImage?
    
    autoreleasepool { 
        
        let imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        var colorspaceRef = CGImageGetColorSpace(imageRef);
        
        let unsupportedColorSpace = (imageColorSpaceModel == .Unknown || imageColorSpaceModel == .Monochrome || imageColorSpaceModel == .CMYK || imageColorSpaceModel == .Indexed)
        if (unsupportedColorSpace)
        {
            colorspaceRef = CGColorSpaceCreateDeviceRGB();
        }
        
        let context = CGBitmapContextCreate(nil, Int(width),
            Int(height),
            8,
            4*Int(width),
            colorspaceRef,
            CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.NoneSkipLast.rawValue);
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef);
        
        let imageRefWithAlpha = CGBitmapContextCreateImage(context);
        
        let scale = image!.scale < UIScreen.mainScreen().scale ? UIScreen.mainScreen().scale : image!.scale
        
        imageWithAlpha = UIImage(CGImage: imageRefWithAlpha!, scale: scale, orientation: image!.imageOrientation)
 
    }
    
    return imageWithAlpha;
    
}


func GifWithData(data:NSData)->UIImage?
{
    let source = CGImageSourceCreateWithData(data,gifProperties as CFDictionaryRef)
 
    if source == nil {return UIImage(data: data)}
    
    let count = CGImageSourceGetCount(source!)
    
    var animatedImage:UIImage?
    
    if (count <= 1) {
        animatedImage = UIImage(data: data)
    }
    else {
        
        var duration:NSTimeInterval = 0.0

        var images:[UIImage] = []
        
        for i in 0..<count
        {
            let image = CGImageSourceCreateImageAtIndex(source!, i, gifProperties)
            
            if (image ==  nil) {
                continue;
            }
            
            let d=CGImageSourceCopyPropertiesAtIndex(source!, i, nil)! as CFDictionaryRef
            
            let dict = d as Dictionary
            
            let gifDict:Dictionary<String,NSObject>?=dict[kCGImagePropertyGIFDictionary as String] as? Dictionary
            
            var temp:NSTimeInterval = 0.0
            
            if let dict = gifDict
            {
                let delayTimeUnclampedProp:NSNumber? = dict[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
                
                if delayTimeUnclampedProp != nil
                {
                    temp = NSTimeInterval(delayTimeUnclampedProp!.doubleValue)
                }
                else
                {
                    let delayTimeProp:NSNumber? = dict[kCGImagePropertyGIFDelayTime as String] as? NSNumber
                    
                    if (delayTimeProp != nil) {
                        temp = NSTimeInterval(delayTimeProp!.doubleValue)
                    }
                }
                
                if (temp < 0.011) {
                    temp = 0.100
                }
                
                duration += temp
                
            }
            
            images.append(UIImage(CGImage: image!, scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Up))
        }
        
        if (duration == 0.0) {
            duration = 1.0 / 10.0 * Double(count)
        }

        animatedImage = UIImage.animatedImageWithImages(images, duration: duration)
    }
    
    return animatedImage;
    
}

let XImageSavePath = (NSSearchPathForDirectoriesInDomains(.CachesDirectory,.UserDomainMask, true)[0] as NSString).stringByAppendingPathComponent("XNetImage")

//let DefaultImage = "bucket_no_picture@2x.png".image

class XImageUtil: NSObject,NSURLSessionDataDelegate {
    
    static let Share = XImageUtil.init()
    var taskList:Dictionary<Int,XImageDownLoader>=[:]
    var session:NSURLSession!
    var memCache = XImageCache()
    var immediately = true
    
    var config:NSURLSessionConfiguration!
    
    var XNetImagebackgroundUpdateTask:UIBackgroundTaskIdentifier?
    
    static var prossColor = UIColor(red: 43.0/255.0, green: 97.0/255.0, blue: 192.0/255.0, alpha: 1.0)
    
    static let FileManager = NSFileManager.defaultManager()
    
    var netState:ReachabilityStatus = .Unknown
    
    var maxCacheSize:Int = 1024*1024*50
    {
        willSet
        {
            
        }
        didSet
        {
            memCache.totalCostLimit = maxCacheSize
        }
    }
    
    var autoDown:AutoDownLoadType = .All
        {
        willSet
        {
            
        }
        didSet
        {
            NSUserDefaults.standardUserDefaults().setInteger(autoDown.rawValue, forKey: "XImageAutoDownType")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.autoTypeChanged()
            
            XImageOperationManager.Share.operation.cancelAllOperations()
            
//            for (_,value) in self.taskList
//            {
//                value.cancel()
//            }
            
            self.taskList.removeAll(keepCapacity: false)
        }
    }
    
    
    private override init() {
        super.init()

        XImageGifPool.Share
        
        maxCacheSize = Int(Double(NSProcessInfo.processInfo().physicalMemory)*0.1)
        
        memCache.totalCostLimit = maxCacheSize
        memCache.countLimit = 0
        memCache.evictsObjectsWithDiscardedContent = false
        
        if(!NSFileManager.defaultManager().fileExistsAtPath(XImageSavePath))
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(XImageSavePath, withIntermediateDirectories: true, attributes: nil)
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XImageUtil.networkStatusChanged(_:)), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
        
        netState = Reach().connectionStatus()
        
        if let raw = NSUserDefaults.standardUserDefaults().valueForKey("XImageAutoDownType") as? Int
        {
            self.autoDown = AutoDownLoadType(rawValue: raw)!
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XImageUtil.enterBack), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XImageUtil.removeAllMemCache), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        if #available(iOS 8.0, *) {
            self.config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("XNetImage-xpf")
        } else {
            //self.config = NSURLSessionConfiguration.backgroundSessionConfiguration("XNetImage-xpf")
            self.config = NSURLSessionConfiguration.defaultSessionConfiguration()
        }
        
        self.config.timeoutIntervalForRequest = 0
        self.config.timeoutIntervalForResource = 0
        self.config.HTTPMaximumConnectionsPerHost = 5
        self.config.HTTPAdditionalHeaders = ["User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36","Content-Type":"text/plain; charset=utf-8 ","Accept":"*/*","Accept-Encoding":"gzip, deflate, sdch"]
        
        let operation = NSOperationQueue()
        operation.maxConcurrentOperationCount = 10
        
        
        
        self.session = NSURLSession(configuration: self.config, delegate: self, delegateQueue: operation)
        
    }
    
    
    
    class func ImageCachesSize() -> Double
    {
        var cachesSize:Double = 0
        let manager:NSFileManager = NSFileManager.defaultManager()
        let filePath = XImageSavePath
        let allFileArray:Array<String>? = manager.subpathsAtPath(filePath)
        
        if(allFileArray != nil)
        {
            let arr:NSArray = NSArray(array: allFileArray!)
            let subFilesEnemerator:NSEnumerator=arr.objectEnumerator()
            var fileName:String?
            
            while(subFilesEnemerator.nextObject() != nil)
            {
                fileName = subFilesEnemerator.nextObject() as? String
                
                if(fileName != nil)
                {
                    let fileAbsolutePath:String = (filePath as NSString).stringByAppendingPathComponent(fileName!)
                    if(manager.fileExistsAtPath(fileAbsolutePath))
                    {
                        do
                        {
                            let dic:NSDictionary? = try manager.attributesOfItemAtPath(fileAbsolutePath)
                            
                            if(dic != nil)
                            {
                                cachesSize = cachesSize + Double(dic!.fileSize())
                            }
                        }
                        catch
                        {
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
        return cachesSize;
    }
    
    class func removeAllFile()
    {
        let manager:NSFileManager = NSFileManager.defaultManager()
        let TempPath = XImageSavePath
        var paths:[String]?
        
        do
        {
            paths = try manager.contentsOfDirectoryAtPath(TempPath)
        }
        catch
        {
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            do
            {
                for item in paths!
                {
                    let path =  (TempPath as NSString).stringByAppendingPathComponent(item)
                    try manager.removeItemAtPath(path)
                    
                }
                
            }
            catch
            {
                
            }
            
        })
        
    }
    
    class func removeAllMemCache()
    {
        XImageGifPool.Share.caches.removeAll(keepCapacity: false)
        Share.memCache.removeAllObjects()
    }
    
    
    func networkStatusChanged(notification: NSNotification) {
        let userInfo = notification.userInfo
        
        if((userInfo!["Status"] as! String).rangeOfString("WiFi") != nil)
        {
            netState = .Online(.WiFi)
            
            if autoDown == .WiFi || autoDown == .All
            {
                for (_,value) in self.taskList
                {
                    value.startDownLoad()
                }
            }
            
        }
        else if((userInfo!["Status"] as! String).rangeOfString("WWAN") != nil)
        {
            netState = .Online(.WWAN)
            
            if autoDown == .WWAN || autoDown == .All
            {
                for (_,value) in self.taskList
                {
                    value.startDownLoad()
                }
            }
        }
        else
        {
            netState = .Unknown
        }
        
        self.autoTypeChanged()
        
    }
    
    
    private func autoTypeChanged()
    {
        var need = false
        
        if autoDown == .None{need = true}
        
        switch netState {
            
        case .Unknown, .Offline:
            
            ""
            need = true
            
        case .Online(.WWAN):
            
            ""
            
            if autoDown == .WiFi
            {
                need = true
            }
            
            
        case .Online(.WiFi):
            
            ""
            
            if autoDown == .WWAN
            {
                need = true
            }
            
        }
        
        self.immediately = !need
        
    }
    
    
    
    
    
    func enterBack()
    {
        self.beingBackgroundUpdateTask()
    }
    
    func  beingBackgroundUpdateTask()
    {
        XNetImagebackgroundUpdateTask=UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            self.endBackgroundUpdateTask()
        })
    }
    
    func endBackgroundUpdateTask()
    {
        UIApplication.sharedApplication().endBackgroundTask(self.XNetImagebackgroundUpdateTask!)
        self.XNetImagebackgroundUpdateTask = UIBackgroundTaskInvalid
    }
    
    class func preDownLoad(url:String)
    {
        Share.createTask(url).startDownLoad()
    }
    
    func createTask(url:String)->XImageDownLoader
    {
        let hash = url.hash
        var downloader:XImageDownLoader!
        if let d = XImageUtil.Share.taskList[hash]
        {
            downloader = d
        }
        else
        {
            downloader = XImageDownLoader()
            downloader.url = url
            taskList[hash] = downloader
        }
        
        return downloader
    }
    
    func removeTask(hash:Int)
    {
        if let _ = self.taskList[hash]
        {
            self.taskList.removeValueForKey(hash)
        }
    }
    
    func getDownLoaderByTask(task:NSURLSessionTask)->XImageDownLoader?
    {
        for (_,value) in self.taskList
        {
            if value.task == nil {continue}
            
            if task == value.task
            {
                return value
            }
        }
        
        return nil
    }
    
    
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        if let downloader = self.getDownLoaderByTask(dataTask)
        {
            downloader.data?.appendData(data)
            downloader.sendProgress(CGFloat(dataTask.countOfBytesReceived)/CGFloat(dataTask.countOfBytesExpectedToReceive))
            
        }
        
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if let downloader = self.getDownLoaderByTask(dataTask)
        {
            downloader.data = NSMutableData()
            downloader.sendProgress(0.0)
        }
        
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let downloader = self.getDownLoaderByTask(task)
        {
            let (image,data) = downloader.saveFile(error)
            
            autoreleasepool({ () -> () in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    downloader.downComplete(image,data: data)
                })
                
            })
            
        }
        
    }
    
    
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        //认证服务器（这里不使用服务器证书认证，只需地址是我们定义的几个地址即可信任）
        if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodServerTrust
        {
            
            let credential = NSURLCredential(forTrust:
                challenge.protectionSpace.serverTrust!)
            credential.certificates
            completionHandler(.UseCredential, credential)
        }
            
            //认证客户端证书
        else if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodClientCertificate
        {
            
        }
            
            // 其它情况（不接受认证）
        else {
            completionHandler(.CancelAuthenticationChallenge, nil);
        }
        
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        let appDelegate = UIApplication.sharedApplication().delegate
        
        appDelegate?.application?(UIApplication.sharedApplication(), handleEventsForBackgroundURLSession: "XNetImage-xpf") { () -> Void in
            
            
        }
        
    }
    
    
}