//
//  SecondViewController.swift
//  XLYTextKitExtensionDemo
//
//  Created by kaizei on 16/1/6.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYTextKitExtension


class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let customView = CustomView()
        customView.contentInsets = UIEdgeInsetsMake(30, 30, 30, 30)
        customView.backgroundColor = UIColor.lightGray
        customView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customView)
        
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[v]-50-|", options: [], metrics: nil, views: ["v": customView])
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-80-[v(200)]", options: [], metrics: nil, views: ["v": customView])
        )
        
        let storage = customView.storage
        
        // normal text
        let text1 = NSAttributedString(string: "normal + ", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 14)])
        storage.append(text1)
        
        // view attachment
        let images = (0...3).map{ UIImage(named: "dog\($0)")! }
        let gifAttachment = XLYTextAttachment { () -> UIView in
            let animatedImageView = UIImageView()
            animatedImageView.backgroundColor = .purple
            animatedImageView.animationImages = images
            animatedImageView.animationDuration = 0.6
            animatedImageView.startAnimating()
            return animatedImageView
        }
        gifAttachment.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        let text2 = NSAttributedString(attachment: gifAttachment)
        storage.append(text2)
        
        // for all component in storage, we draw the outline and baseline
        let outline = XLYPainter(type: .foreground, handler: combinePainters([strokeLineUsedRect(color: .red, lineDashLengths:[2, 2]), strokeBaseline(color: .green)]))
        storage.addAttribute("outline", value: outline, range: NSMakeRange(0, storage.length))
    }

}

// just an example. can be much more complicated.
open class CustomView: UIView {
    open let storage = NSTextStorage()
    open var contentInsets = UIEdgeInsets.zero
    
    let layoutManager = XLYTextLayoutManager()
    let container = NSTextContainer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.associatedView = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.associatedView = self
    }
    
    open override func draw(_ rect: CGRect) {
        container.size = UIEdgeInsetsInsetRect(rect, contentInsets).size
        let origin = CGPoint(x: contentInsets.left, y: contentInsets.top)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSMakeRange(0, storage.length), actualCharacterRange: nil)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
    }
}
