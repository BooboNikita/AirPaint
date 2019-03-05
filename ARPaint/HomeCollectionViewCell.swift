//
//  HomeCollectionViewCell.swift
//  ARPaint
//
//  Created by 包笛 on 2018/3/14.
//  Copyright © 2018年 Apple. All rights reserved.
//

import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    var imageView: SVGKLayeredImageView?
//    var imageStr: String? {
//
//        didSet {
//            self.imageView!.image = UIImage(named: self.imageStr!)
//        }
//
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = SVGKLayeredImageView(frame: self.bounds)
        self.addSubview(self.imageView!)
        
//        imageView?.isUserInteractionEnabled = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.frame = self.bounds
        self.imageView?.contentMode = UIViewContentMode.center
        self.imageView?.transform = CGAffineTransform(scaleX: 0.04, y: 0.04)
        self.imageView?.sizeToFit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
