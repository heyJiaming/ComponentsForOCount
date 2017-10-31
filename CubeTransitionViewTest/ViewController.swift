//
//  ViewController.swift
//  CubeTransitionViewTest
//
//  Created by 孟嘉明 on 2017/10/10.
//  Copyright © 2017年 孟嘉明. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CubicTransitionProtocol {
    
    var contentViews: [UIView]!
    var numberOfContentViews = 4
    var cubicTransitionView: CubicTransitionView!
    var cubicTransitionViewFrame: CGRect!
    
    @IBOutlet weak var numOfViewsTextField: UITextField!
    
    @IBOutlet weak var sideToRotateTextField: UITextField!
    
    @IBOutlet weak var sidePortionLabel1: UILabel!
    @IBOutlet weak var sidePortionLabel2: UILabel!
    var sidePortionLabels: [UILabel]!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sidePortionLabels = [sidePortionLabel1, sidePortionLabel2]
        
        cubicTransitionViewFrame = CGRect(x: 0, y: 50, width: self.view.frame.width, height: self.view.frame.height - 100)
        
        generateContentViews()

    }
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.isOn{
            cubicTransitionView.isRotationSpringy = true
        }
        else{
            cubicTransitionView.isRotationSpringy = false
        }
    }
    
    private func generateContentViews()
    {
        if cubicTransitionView != nil
        {
            cubicTransitionView.removeFromSuperview()
        }
        
        contentViews = []
        
        for i in 0 ..< numberOfContentViews
        {
            let newContainerView = ContainerView(frame: cubicTransitionViewFrame, i: i)
            contentViews.append(newContainerView)
        }
        cubicTransitionView = CubicTransitionView(frame: cubicTransitionViewFrame, contentViews: contentViews)!
        cubicTransitionView.transitionDelegate = self
        
        self.view.insertSubview(cubicTransitionView, at: 0)
    }
    
    @IBAction func changeNumOfViews(_ sender: Any) {
        guard let string = numOfViewsTextField.text
            else {
                return
        }
        guard let int = Int(string)
            else {
            return
        }
        
        numberOfContentViews = int
        
        generateContentViews()
    }
    
    @IBAction func rotateToSide(_ sender: Any) {
        guard let string = sideToRotateTextField.text
            else {
                return
        }
        guard let int = Int(string)
            else {
                return
        }
        
        cubicTransitionView.rotateToSide(side: int)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayedPortion(begin: CGFloat, end: CGFloat)
    {
        sidePortionLabel1.text = "\(begin)"
        sidePortionLabel2.text = "\(end)"
    }

    func didRotateTo(side: Int) {
        let alertVC = UIAlertController(title: "Rotated to side\(side)", message: nil, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "ok", style: .default, handler:
        {
            _ in
            alertVC.dismiss(animated: true, completion: nil)
        })
        alertVC.addAction(alertAction)
        self.present(alertVC, animated: true, completion: nil)
    }

}

