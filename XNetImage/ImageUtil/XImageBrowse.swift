//
//  XImageBrowse.swift
//  chengshi
//
//  Created by X on 15/11/28.
//  Copyright © 2015年 XSwiftTemplate. All rights reserved.
//

import UIKit
import AVFoundation

class XImageBrowse: UIView,UIScrollViewDelegate,zoomScrollDelegate,UICollectionViewDelegate,UICollectionViewDataSource {

    //static let Share = XImageBrowse(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
    
    var collection:UICollectionView!
    let clayout = UICollectionViewFlowLayout()
    
    lazy var imageArr:Array<UIImageView> = []
    var beginFrame:CGRect = CGRectZero
    var index:Int=0
    var showIng:Bool=false
    
    let startBGC = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    let endBGC = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    let swidth = UIScreen.mainScreen().bounds.width
    let sheight = UIScreen.mainScreen().bounds.height

    convenience init(arr:[UIImageView])
    {
        self.init(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        self.imageArr = arr
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clayout.scrollDirection = .Horizontal
        clayout.minimumLineSpacing = 0.0
        clayout.minimumInteritemSpacing = 0.0
        clayout.itemSize = CGSizeMake(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        
        collection = UICollectionView(frame: frame, collectionViewLayout: clayout)
        collection.backgroundColor = UIColor.blackColor()
        collection.bounces = true
        collection.clipsToBounds = true
        collection.pagingEnabled = true
        collection.layer.masksToBounds = true
        collection.delegate = self
        collection.dataSource = self
        
        collection.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        collection.alpha = 0.0
        
        self.userInteractionEnabled = true
        self.backgroundColor = startBGC
        
        self.addSubview(collection)
  
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.imageArr.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        
        for item in cell.contentView.subviews
        {
            item.removeFromSuperview()
        }
        
        let i = indexPath.row
        let item = self.imageArr[i]
        
        let zoomScrollView:MRZoomScrollView = MRZoomScrollView(img: item)

        zoomScrollView.frame = CGRectMake(0, 0, swidth, sheight)
        
        zoomScrollView.tag=70+i
        zoomScrollView.zoomDelegate=self
        cell.contentView.addSubview(zoomScrollView)
        
        return cell
    }
    
    
    func show(img:UIImageView)
    {
        let index = self.imageArr.indexOf(img)
        let frame=img.superview?.convertRect(img.frame, toView: UIApplication.sharedApplication().keyWindow)
        if index == nil || frame == nil {return}
        
        self.showIng = true
        self.index = index!
        
        self.beginFrame = frame!
    
        self.collection.reloadData()
        
        let indexPath = NSIndexPath(forRow: index!, inSection: 0)
        
        self.collection.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Left, animated: false)
        
        UIApplication.sharedApplication().keyWindow?.addSubview(self)
        

        self.show()
        
    }
    
    private func show()
    {
        
        let fromImage = imageArr[index]
        
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.frame = beginFrame
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        self.addSubview(view)
        
        let toImage = UIImageView()
        toImage.image = fromImage.image
        view.addSubview(toImage)

        toImage.frame = trueFrame(fromImage)
        toImage.center = imgCenter(beginFrame, img: fromImage)
        toImage.contentMode = .ScaleToFill
        
        var rect = CGRectZero
        
        if fromImage.image != nil
        {
            rect = AVMakeRectWithAspectRatioInsideRect(fromImage.image!.size, CGRectMake(0, 0, self.swidth, self.sheight))
        }
        
        fromImage.alpha = 0.0
        
        UIView.animateWithDuration(0.3, animations: {
            
            view.frame = CGRectMake(0, 0, self.swidth, self.sheight)
            
            toImage.frame = rect
            
            self.backgroundColor = self.endBGC
            
            }, completion: {
                
                (completion) in
                
                toImage.removeFromSuperview()
                view.removeFromSuperview()
                self.collection.alpha = 1.0
                fromImage.alpha = 1.0
                
            })
    }
    
    
    
    func hide()
    {
        index = Int(floor(self.collection.contentOffset.x / swidth))
        
        let temp=viewWithTag(70+index) as! MRZoomScrollView
        
        temp.fixImage()
        
        let view = UIView()
        view.frame = CGRectMake(0, 0, swidth, sheight)
        view.backgroundColor = UIColor.clearColor()
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        
        let fromImg = temp.imageView!
        
        
        
        let fromeFrame = fromImg.superview?.convertRect(fromImg.frame, toView: UIApplication.sharedApplication().keyWindow)
        
        view.addSubview(fromImg)
        
        if fromeFrame != nil{
            
            fromImg.frame = fromeFrame!
        }
        
        self.collection.alpha = 0.0

        let toImg = imageArr[index]
        if toImg.image == nil
        {
            toImg.image = temp.imageView!.image
            if toImg.isGroup
            {
                toImg.btnLabelHidden(true)
            }
        }
        let toFrame = trueFrame(toImg)
        
        if toImg.contentMode == .Redraw || toImg.contentMode == .ScaleToFill
        {
            fromImg.contentMode = .ScaleToFill
        }
        
        fromImg.clipsToBounds = toImg.clipsToBounds
        fromImg.layer.masksToBounds = toImg.layer.masksToBounds
        
        
        let toViewFrame = toImg.superview?.convertRect(toImg.frame, toView: UIApplication.sharedApplication().keyWindow)
        
        if toViewFrame != nil && fromeFrame != nil
        {
            self.addSubview(view)
        }
        
        toImg.alpha=0.0
        
        UIView.animateWithDuration(0.3, animations: {
            
            if toViewFrame == nil || fromeFrame == nil
            {
                view.alpha=0.0
                toImg.alpha=1.0
            }
            else
            {
                view.frame = toViewFrame!
                fromImg.frame = toFrame
                fromImg.center = self.imgCenter(view.frame, img: toImg)
            }
            
            self.backgroundColor = self.startBGC
            
            }, completion: {
                
                (completion) in
                toImg.alpha=1.0
                self.imageArr.removeAll(keepCapacity: false)
                self.collection.delegate = nil
                self.collection.dataSource = nil
                self.collection.removeFromSuperview()
                fromImg.removeFromSuperview()
                view.removeFromSuperview()
                self.removeFromSuperview()
                
                
        })
        
    }
    
    func imgCenter(frame:CGRect,img:UIImageView)->CGPoint
    {
        
        switch img.contentMode
        {

        case .Top:
            ""
            return CGPointMake(frame.width/2.0, img.image!.size.height/2.0)
            
        case .Bottom:
            ""
            return CGPointMake(frame.width/2.0, -(img.image!.size.height/2.0-frame.height))
            
        case .Left:
            ""
            return CGPointMake(img.image!.size.width/2.0, frame.height/2.0)
         
        case .Right:
            ""
            return CGPointMake(-(img.image!.size.width/2.0-frame.width), frame.height/2.0)
            
        case .TopLeft:
            ""
            return CGPointMake(img.image!.size.width/2.0, img.image!.size.height/2.0)
            
        case .TopRight:
            ""
            return CGPointMake(-(img.image!.size.width/2.0-frame.width), img.image!.size.height/2.0)
            
        case .BottomLeft:
            ""
            return CGPointMake(img.image!.size.width/2.0, -(img.image!.size.height/2.0-frame.height))
            
        case .BottomRight:
            ""
            return CGPointMake(-(img.image!.size.width/2.0-frame.width), -(img.image!.size.height/2.0-frame.height))
            
        default:
            ""
            
            return CGPointMake(frame.width/2.0, frame.height/2.0)
        }
        
        
    }
    
    func trueFrame(img:UIImageView)->CGRect
    {
        if img.image == nil {return img.frame}
        
        switch img.contentMode
        {
        case .Center,.Top,.Bottom,.Left,.Right,.TopLeft,.TopRight,.BottomLeft,.BottomRight:
            ""
            return CGRectMake(0, 0, img.image!.size.width, img.image!.size.height)
            
        case .ScaleAspectFit:
            ""
            
            let frame = img.frame
            let rect = AVMakeRectWithAspectRatioInsideRect(img.image!.size, img.bounds)
            
            let x = frame.origin.x + rect.origin.x
            let y = frame.origin.y + rect.origin.y
            
            return CGRectMake(x, y , rect.size.width, rect.size.height)
            
        case .ScaleAspectFill:
            ""
            let hw = img.frame.height / img.frame.width
            let hw1 = img.image!.size.height / img.image!.size.width
            var height:CGFloat = 0.0
            var width:CGFloat = 0.0
            if hw < hw1
            {
                width = img.frame.width
                height = hw1 * width
            }
            else
            {
                height = img.frame.height
                width = 1 / hw1 * height
            }
            
            return CGRectMake(0, 0 , width, height)
            
            
        default:
            ""
            
            return img.frame
        }
        
    }
    
    

    func zoomTapClick() {
        
        self.hide()
    }

    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit
    {
        print("\(#function) in \(#file.componentsSeparatedByString("/").last!.stringByReplacingOccurrencesOfString(".swift", withString: ""))")
    }

}
