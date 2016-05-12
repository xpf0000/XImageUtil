# XImageUtil
网络图片加载库

一 说明:

使用NSURLSession+NSOperation+NSOperationQueue 构建的Swift版网络图片加载库 包含物理缓存和内存缓存 支持后台下载

可以分网络选择下载(wifi,3G,手动,自动) 

根据UIImageView的大小自动调整图片大小 内存占用更小   

支持GIF WEBP , GIF使用自定义方法显示 加载速度更快 占用内存更小

支持点击放大 群组浏览 支持各种contentMode

二 项目引用:

直接把ImageUtil文件夹拷贝到项目中 如果想支持WEBP 在桥接文件中 添加 #import "UIImage+WebP.h"  

三 使用:

主要是UIImageView扩展出来的属性

  1. url: 图片url地址 

    显示图片  

    let imageView = UIImageView(frame:CGRectMake(0,0,100,100))

    imageView.url = "http://xxxxxxxxxxx.jpg"

    直接下载图片  

    XImageUtil.preDownLoad("http://xxxxxxxxx.jpg")

  2. placeholder: 默认图片

    let imageView = UIImageView(frame:CGRectMake(0,0,100,100))

    imageView.placeholder = UIImage()

  3. isGroup: 是否隶属于一组图片  true的时候 图片可以点击放大 并可在这组图片之间滑动切换 以父视图中所有isGroup为true的UIImageView作为该组所有图片

    let imageView = UIImageView(frame:CGRectMake(0,0,100,100))

    imageView.isGroup = true

  4. groupDelegate: 组代理 针对于 UICollectionView 等 无法放到一个父视图中的UIImageView使用 需实现代理方法

  var imgArr:[Int:UIImageView] = [:]

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TestCell", forIndexPath: indexPath) as! TestCell

        cell.img.groupDelegate = self

        imgArr[indexPath.row] = cell.img
        
        return cell
        
        
    }
    
    func XImageViewGroupTap(obj: UIImageView) {
        
        var arr:[UIImageView] = []
        
        for i in 0..<imgArr.count
        {
            arr.append(imgArr[i]!)
        }
        
        XImageBrowse(arr: arr).show(obj)

    }
    
      5  设定网络环境
    
        手动: XImageUtil.Share.autoDown = .None
    
        自动: XImageUtil.Share.autoDown = .All
    
        wifi: XImageUtil.Share.autoDown = .WiFi
    
        流量: XImageUtil.Share.autoDown = .WWAN
      
      6. 删除缓存
    
        删除内存缓存: XImageUtil.removeAllMemCache()
    
        删除硬盘文件: XImageUtil.removeAllFile()
    

