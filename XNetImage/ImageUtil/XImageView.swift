//
//  UIImageView.swift
//  swiftTest
//
//  Created by X on 15/3/11.
//  Copyright (c) 2015年 swiftTest. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

var testD:XImageDownLoader?

class XImgProgressModel: NSObject {
    
    weak var imgView:UIImageView?
    var block:XImageProgressBlock?
    var xhash = 0
    
}

class XImgCompleteModel: NSObject {
    
    weak var imgView:UIImageView?
    var block:XImageCompleteBlock?
    var xhash = 0
    
}


@objc protocol XImageViewGroupDelegate:NSObjectProtocol{
    //回调方法
    optional func XImageViewGroupTap(obj:UIImageView)
}

private var XImageUrlKey : CChar = 0
private var XImagePlaceholderKey : CChar = 0
private var XImageCAShapeLayerKey:CChar = 0
private var XImageControllBtnKey:CChar = 0
private var XImageGroupDelegateKey:CChar = 0
private var XImageIsGroupKey:CChar = 0
private var XImageHasLayouted:CChar = 0

let IOQueue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

extension UIImageView
{
    
    private var hasLayouted:Bool?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImageHasLayouted) as? Bool
        }
        set(newValue) {
            self.willChangeValueForKey("XImageHasLayouted")
            objc_setAssociatedObject(self, &XImageHasLayouted, newValue,
                                     .OBJC_ASSOCIATION_ASSIGN)
            self.didChangeValueForKey("XImageHasLayouted")
 
        }
    }
    
    var placeholder:UIImage?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImagePlaceholderKey) as? UIImage
        }
        set(newValue) {
            self.willChangeValueForKey("XImagePlaceholderKey")
            objc_setAssociatedObject(self, &XImagePlaceholderKey, newValue,
                .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValueForKey("XImagePlaceholderKey")
            
            if self.url == nil {self.image = newValue;return}
            
            if let d = XImageUtil.Share.taskList[self.url!.hash]
            {
                if !d.taskRunning || d.task == nil
                {
                    self.image = newValue
                }
            }
            
        }
    }
    
    var groupDelegate:XImageViewGroupDelegate?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImageGroupDelegateKey) as? XImageViewGroupDelegate
        }
        set {
            
            self.willChangeValueForKey("XImageGroupDelegateKey")
            objc_setAssociatedObject(self, &XImageGroupDelegateKey, newValue,
                .OBJC_ASSOCIATION_ASSIGN)
            self.didChangeValueForKey("XImageGroupDelegateKey")
            
        }
    }
    
    var isGroup:Bool
        {
        get
        {
            let r = objc_getAssociatedObject(self, &XImageIsGroupKey) as? Bool
            
            return r == nil ? false : r!
        }
        set {
            
            self.willChangeValueForKey("XImageIsGroupKey")
            objc_setAssociatedObject(self, &XImageIsGroupKey, newValue,
                .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValueForKey("XImageIsGroupKey")
            self.userInteractionEnabled = true
            
            if controllBtn?.superview == nil
            {
                self.btnLabelHidden(true)
            }
            
        }
    }
    
    
    private var controllBtn:UIButton?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImageControllBtnKey) as? UIButton
        }
        set {
            
            self.willChangeValueForKey("XImageControllBtnKey")
            objc_setAssociatedObject(self, &XImageControllBtnKey, newValue,
                .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValueForKey("XImageControllBtnKey")
            
            
        }
    }
    
    
    private var progressLayer:CAShapeLayer?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImageCAShapeLayerKey) as? CAShapeLayer
        }
        set {
            
            self.willChangeValueForKey("XImageCAShapeLayerKey")
            objc_setAssociatedObject(self, &XImageCAShapeLayerKey, newValue,
                .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValueForKey("XImageCAShapeLayerKey")
        }
    }
    
    private func progressLayerInit()
    {
        if self.progressLayer == nil{
            
            let size = bounds.size
            progressLayer = CAShapeLayer()
            progressLayer!.frame = bounds
            progressLayer!.lineWidth = 2.0
            progressLayer!.fillColor = UIColor.clearColor().CGColor
            progressLayer!.strokeColor = XImageUtil.prossColor.CGColor
            progressLayer!.lineCap = kCALineCapRound
            
            var circleRadius = size.height > size.width ? size.width : size.height
            circleRadius = circleRadius / 2.0 * 0.8
            
            let point = CGPointMake(bounds.width / 2.0,bounds.height / 2.0)
            
            let path = UIBezierPath(arcCenter: point, radius: circleRadius, startAngle: CGFloat(M_PI * 1.0), endAngle: CGFloat(M_PI * 3.0), clockwise: true)
            progressLayer!.path = path.CGPath
            progressLayer?.strokeStart = 0.0
            progressLayer?.strokeEnd = 0.0
            
        }
        
        if progressLayer?.superlayer == nil{
            
            self.layer.addSublayer(progressLayer!)
        }

        
    }
    
    private func controllBtnInit()
    {
        if controllBtn == nil
        {
            controllBtn = UIButton(type: .Custom)
            controllBtn!.frame  = bounds
            controllBtn!.backgroundColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
            
            controllBtn!.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            controllBtn!.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
            
            controllBtn!.contentEdgeInsets = UIEdgeInsetsMake(3,3, 0, 0);
            controllBtn!.titleLabel?.font = UIFont.systemFontOfSize(12.0)
            controllBtn!.setTitle("[点击下载]", forState: .Normal)
            controllBtn!.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
            controllBtn!.addTarget(self, action: #selector(UIImageView.doDownLoad(_:)), forControlEvents: .TouchUpInside)
            
        }
        
        if controllBtn?.superview == nil
        {
            controllBtn?.selected = false
            self.addSubview(controllBtn!)
        }
        
    }
    
    
    var url:String?
        {
        get
        {
            return objc_getAssociatedObject(self, &XImageUrlKey) as? String
        }
        set {
            
            let oldValue = objc_getAssociatedObject(self, &XImageUrlKey) as? String
            
            self.willChangeValueForKey("XImageUrlKey")
            objc_setAssociatedObject(self, &XImageUrlKey, newValue,
                .OBJC_ASSOCIATION_RETAIN)
            self.didChangeValueForKey("XImageUrlKey")
            
            if newValue==nil || newValue==oldValue {return}
            
            self.clipsToBounds = true
            self.layer.masksToBounds = true
            //self.layer.shouldRasterize = true
            self.contentMode = .ScaleAspectFill
            self.userInteractionEnabled = true
            self.image = placeholder
            
            self.progressLayer?.removeFromSuperlayer()
            self.progressLayer?.strokeEnd = 0.0
            
            let immediately = XImageUtil.Share.immediately
            
            if !immediately
            {
                self.controllBtnInit()
            }
            
            self.creatOperation(newValue!, immediately: immediately)
 
        }
        
    }
    
    private func creatOperation(newValue:String,immediately:Bool)
    {
        if newValue == "" {return}
        
        let downloader:XImageDownLoader = XImageUtil.Share.createTask(newValue)
        downloader.immediately = immediately
        downloader.view = self
        
        var has = false
        for item in downloader.progress
        {
            if item.imgView == self && item.xhash == hash  && item.block != nil{
                has = true
                break
            }
        }
        
        if !has
        {
            let progress:XImageProgressBlock = {
                [weak self](url,p)->Void in
                
                if self==nil || url != self?.url {return}
                
                self?.progressLayerInit()
                
                if self?.image != nil {self?.image = nil}
                
                if self?.controllBtn?.superview != nil
                {
                    self?.controllBtn?.removeFromSuperview()
                }
                
                self?.progressLayer?.strokeEnd = p
            }
            
            let pmodel = XImgProgressModel()
            pmodel.imgView = self
            pmodel.block = progress
            pmodel.xhash = hash
            downloader.progress.append(pmodel)
        }
        else
        {
            
        }
        
        
        has = false
        for item in downloader.complete
        {
            if item.imgView == self && item.xhash == hash  && item.block != nil{
                has = true
                break
            }
        }
        
        if !has
        {
            let complete:XImageCompleteBlock = {
                [weak self](url,image,data)->Void in
                
                if self==nil || url != self?.url {return}
                
                self?.progressLayer?.removeFromSuperlayer()
                
                if image != nil
                {
                    self?.image = image
                    self?.alpha = 0.0
                    
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        self?.alpha = 1.0
                    })
                    
                    if self?.isGroup == true
                    {
                        self?.btnLabelHidden(true)
                    }
                    else
                    {
                        self?.controllBtn?.removeFromSuperview()
                    }
                }
                else
                {
                    self?.btnLabelHidden(false)
                }
                
                if data != nil
                {
                    XImageGifPlayer(hash: url.hash, data: data!, img: self!).rePlay()
                }
                
            }
            
            
            let cmodel = XImgCompleteModel()
            cmodel.imgView = self
            cmodel.block = complete
            cmodel.xhash = hash
            downloader.complete.append(cmodel)
        }
        else
        {
            
        }
        
        if self.hasLayouted == nil
        {
            self.layoutIfNeeded()
            self.setNeedsLayout()
        }
        
        if !XImageOperationManager.Share.operation.operations.contains(downloader) && !downloader.finished
        {
            XImageOperationManager.Share.operation.addOperation(downloader)
            
            if XImageOperationManager.Share.lastOperation?.dependencies.count == 0
            {
                XImageOperationManager.Share.lastOperation?.addDependency(downloader)
            }
        
            XImageOperationManager.Share.lastOperation = downloader
            
        }
        else
        {
            if immediately{downloader.startDownLoad()}
        }
        
    }

    func doDownLoad(sender:UIButton)
    {
        if !sender.selected
        {
            self.creatOperation(self.url!, immediately: true)
        }
        else
        {
            if self.groupDelegate != nil
            {
                self.groupDelegate?.XImageViewGroupTap?(self)
            }
            else
            {
                if self.superview == nil {return}
                //XImageBrowse.Share.imageArr.removeAll(keepCapacity: false)
                var arr:[UIImageView] = []
                for item in self.superview!.subviews
                {
                    if let view = item as? UIImageView
                    {
                        if view.isGroup
                        {
                            arr.append(view)
                        }
                    }
                }
                
                XImageBrowse(arr: arr).show(self)
            }
            
            
            
        }
        
        
    }
    
    func btnLabelHidden(hidden:Bool)
    {
        self.controllBtnInit()
        
        controllBtn!.enabled = true
        
        var alpha:CGFloat = 0.0
        var bgColor = UIColor.clearColor()
        if hidden
        {
            alpha = 0.0
            bgColor = UIColor.clearColor()
            
            controllBtn!.selected = true
        }
        else
        {
            alpha = 1.0
            bgColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
            
            controllBtn!.selected = false
        }
        
        for view in controllBtn!.subviews
        {
            view.alpha = alpha
        }
        controllBtn!.backgroundColor = bgColor
        
    }
    
    public override func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.hasLayouted = true

        if self.url != nil
        {
            if controllBtn?.frame != bounds
            {
                controllBtn?.frame = bounds
                progressLayer?.frame = bounds
                
                var circleRadius = bounds.size.height > bounds.size.width ? bounds.size.width : bounds.size.height
                circleRadius = circleRadius / 2.0 * 0.8
                
                let point = CGPointMake(bounds.width / 2.0, bounds.height / 2.0)
                
                let path = UIBezierPath(arcCenter: point, radius: circleRadius, startAngle: CGFloat(M_PI * 1.0), endAngle: CGFloat(M_PI * 3.0), clockwise: true)
                progressLayer?.path = path.CGPath
            }

        }
        
        
        
    }
    
    
}


