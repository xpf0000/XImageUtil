//
//  VC2.swift
//  XNetImage
//
//  Created by X on 16/3/8.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit


class VC2: UIViewController,UITableViewDelegate,UITableViewDataSource,XImageViewGroupDelegate {

    let table = UITableView()
    
    let swidth = UIScreen.mainScreen().bounds.width
    let sheight = UIScreen.mainScreen().bounds.height

    
    override func viewDidLoad() {
        super.viewDidLoad()

        table.frame = CGRectMake(0, 0, swidth, sheight)
        table.delegate = self
        table.dataSource = self
        
        self.view.addSubview(table)
        
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        table.tableFooterView = view
        table.tableHeaderView = view
        
        //table.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        table.registerNib(UINib(nibName: "TestCell", bundle: nil), forCellReuseIdentifier: "TestCell")
        
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 20
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 95
        
    }
    
    var imgArr:[Int:UIImageView] = [:]
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TestCell", forIndexPath: indexPath) as! TestCell
        
        cell.show()

        imgArr[indexPath.row] = cell.img
        
        cell.img.groupDelegate = self
        
        return cell
        
        
    }
    
    
    func XImageViewGroupTap(obj: UIImageView) {
        
        var arr:[UIImageView] = []
        
        for i in 0..<imgArr.count
        {
            arr.append(imgArr[i]!)
        }
        
        XImageBrowse(arr: arr).show(obj)
        
        //XImageBrowse.Share.imageArr = arr
        //XImageBrowse.Share.show(obj)
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
        
        
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
