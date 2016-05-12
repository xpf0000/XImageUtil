//
//  MRZoomScrollView.swift
//  swiftTest
//
//  Created by X on 15/3/16.
//  Copyright (c) 2015年 swiftTest. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc protocol zoomScrollDelegate:NSObjectProtocol{
    //回调方法
    optional func zoomTapClick()
}

class MRZoomScrollView:UIScrollView,UIScrollViewDelegate
{
    var url:String?
    var imageView:UIImageView?
    var scroll:CGFloat?
    weak var zoomDelegate:zoomScrollDelegate?
    var canScroll:Bool?
    var wh:CGFloat=0.0
    var topOffset:CGFloat = 0.0

    let swidth=UIScreen.mainScreen().bounds.size.width
    let sheight=UIScreen.mainScreen().bounds.size.height
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func initSelf()
    {
        self.delegate=self
        self.frame = CGRect(x: 0, y: 0, width: swidth, height: sheight)
        self.maximumZoomScale = 2.0;
        self.minimumZoomScale = 1.0;
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.userInteractionEnabled=true;
        self.scrollEnabled = false
        
        let singleTapGestureRecognizer=UITapGestureRecognizer(target: self, action: #selector(MRZoomScrollView.singleTap))
        singleTapGestureRecognizer.numberOfTapsRequired=1
        self.addGestureRecognizer(singleTapGestureRecognizer)
        
        let doubleTapGesture=UITapGestureRecognizer(target: self, action: #selector(MRZoomScrollView.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired=2
        self.addGestureRecognizer(doubleTapGesture)
        
        singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGesture)
        
    }
    
    init(img:UIImageView)
    {
        self.init()
        
        self.initSelf()
        
        self.url = img.url
        scroll=0.0
        canScroll=false
        
        imageView=UIImageView(frame: CGRectZero)
        imageView!.clipsToBounds = true
        imageView!.layer.masksToBounds = true
        imageView!.frame=CGRectMake(0, 0, swidth,swidth*0.75)
        imageView!.center = CGPointMake(swidth/2, sheight/2+(topOffset/2.0));
        imageView!.contentMode = .ScaleAspectFit
        
        imageView?.addObserver(self, forKeyPath: "image", options: .New, context: nil)
        
        self.addSubview(imageView!)

        if let h = img.url?.hash
        {
            let path = (XImageSavePath as NSString).stringByAppendingPathComponent("\(h)")
            
            if XImageUtil.FileManager.fileExistsAtPath(path)
            {
                let d = NSData(contentsOfFile: path)
                
                if let data = d
                {
                    let type = ImageTypeForData(data)
                    
                    imageView?.image = UIImage(data: data)
                    
                    if type == .GIF
                    {
                        XImageGifPlayer(hash: img.url!.hash, data: data, img: imageView!).rePlay()
                    }
                }
            }
            else
            {
                imageView?.url = img.url
            }
        }
        else
        {
            imageView?.image = img.image
        }
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "image"
        {
            if self.imageView?.image != nil
            {
                self.fixImage()
                canScroll = true
            }
            else
            {
                canScroll = false
            }
        }
        
    }
    
    func singleTap()
    {
        self.zoomDelegate?.zoomTapClick?()
    }
    
    func handleDoubleTap(gesture:UIGestureRecognizer)
    {
        scroll=scroll==0.0 ? 2.0 : 0.0
        self.setZoomScale(scroll!, animated: true)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        if(canScroll==true)
        {
            return imageView
        }
        else
        {
            return nil
        }
    }
    
    func fixImage()
    {
        if wh == 0.0 && imageView?.image != nil
        {
            wh = imageView!.image!.size.height / imageView!.image!.size.width
            
            let image = imageView!.image
            let rect = AVMakeRectWithAspectRatioInsideRect(imageView!.image!.size, CGRectMake(0, 0, self.swidth, self.sheight))
            
            imageView!.image = nil
            imageView!.frame=rect
            imageView!.center = CGPointMake(swidth/2, sheight/2+(topOffset/2.0));
            imageView!.contentMode = .ScaleToFill
            
            imageView!.image = image
        }
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        
        //self.fixImage()
        
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView)
    {
        if(wh<1)
        {
            imageView?.center.y = sheight/2+(topOffset/2.0)
        }
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat)
    {
        if scale > 1.0
        {
            self.scrollEnabled = true
        }
        else
        {
            self.scrollEnabled = false
        }

    }
    
    deinit
    {

        print("\(#function) in \(#file.componentsSeparatedByString("/").last!.stringByReplacingOccurrencesOfString(".swift", withString: ""))")
        
        imageView?.removeObserver(self, forKeyPath: "image")
        imageView?.removeFromSuperview()
        imageView=nil
        url=nil
        self.delegate=nil
        self.zoomDelegate=nil
        self.scroll=nil
        self.canScroll=nil

    }
    
}
