//
//  TestCell.swift
//  XNetImage
//
//  Created by X on 16/3/17.
//  Copyright © 2016年 XNetImage. All rights reserved.
//

import UIKit

class TestCell: UITableViewCell {

    @IBOutlet var img: UIImageView!
    
    @IBOutlet var title: UILabel!
    
    @IBOutlet var sname: UILabel!
    
    //lazy var model = TestModel()
    
    func show()
    {
        //img.url = model.PicUrl
        //title.text = model.Title
        //sname.text = model.StoreName
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
