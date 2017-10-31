//
//  ContainerView.swift
//  CubeTransitionViewTest
//
//  Created by 孟嘉明 on 2017/10/11.
//  Copyright © 2017年 孟嘉明. All rights reserved.
//

import UIKit

class ContainerView: UIView {
    var customView: CostumView!
    {
        didSet{
            if customView != nil
            {
                customView.frame = self.bounds
                self.addSubview(customView)
            }
        }
    }
    
    @IBAction func sayName(_ sender: UIButton) {
        print("I am \(customView.name)")
    }
    
    init(frame: CGRect, i: Int) {
        super.init(frame: frame)
        
        let nib = UINib(nibName: "ContentView2", bundle: Bundle.main)
        let newCustomView = nib.instantiate(withOwner: self, options: nil)[0] as! CostumView
        newCustomView.name = "\(i)"
        newCustomView.label.text = "\(i)"
        newCustomView.frame = self.bounds
        customView = newCustomView
        
        self.addSubview(newCustomView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
