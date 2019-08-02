//
//  ThirdViewController.swift
//  XLYTextKitExtensionDemo
//
//  Created by kaizei on 2019/8/2.
//  Copyright © 2019 kaizei. All rights reserved.
//

import UIKit
import XLYTextKitExtension

final class ThirdViewController: UIViewController {
    
    @IBOutlet
    private var container: StaticWrappableContainerView!
    
    @IBOutlet
    private var trailingConstraint: NSLayoutConstraint!
    
    @IBAction func change(_ sender: Any) {
        trailingConstraint.constant = trailingConstraint.constant == 30 ? 100 : 30
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let views: [UIView] = (0..<10).map{ index in
            let button = UIButton()
            button.backgroundColor = .orange
            button.setTitle("button \(index)", for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            return button
        }
        
        container.reset(views, itemSpace: 12, lineSpace: 12)
    }
}
