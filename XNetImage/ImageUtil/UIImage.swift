//
//  UIImage.swift
//  OA
//
//  Created by X on 15/4/29.
//  Copyright (c) 2015年 OA. All rights reserved.
//

import Foundation
import UIKit
extension UIImage{
    
    func scaledToSize(size:CGSize)->UIImage
    {
        var w:CGFloat=size.width
        var h:CGFloat=size.height
        
        w = w == 0 ? 1 : w
        h = h == 0 ? 1 : h
        
        let size:CGSize=CGSizeMake(w, h)
        
        //UIGraphicsBeginImageContext(size);
        
        // 创建一个bitmap的context
        // 并把它设置成为当前正在使用的context
        //Determine whether the screen is retina
        let scale = UIScreen.mainScreen().scale
        if(scale >= 2.0){
            UIGraphicsBeginImageContextWithOptions(size, false, scale);
        }else{
            UIGraphicsBeginImageContext(size);
        }
        // 绘制改变大小的图片
        self.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        
        let newImage:UIImage=UIGraphicsGetImageFromCurrentImageContext();
        
        // End the context
        UIGraphicsEndImageContext();
        
        // Return the new image.
        return newImage;

    }
    
    func data(zip:CGFloat)->NSData?
    {
        return UIImageJPEGRepresentation(self, zip)
    }
    
    var data:NSData?
        {
            if (UIImagePNGRepresentation(self) == nil) {
                
                return UIImageJPEGRepresentation(self, 1)
                
            } else {
                
               return UIImagePNGRepresentation(self)
            }
    }
}