//
//  SecondViewController.swift
//  XLYTextKitExtensionDemo
//
//  Created by kaizei on 16/1/6.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYTextKitExtension
import XAutoLayout


class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let customView = CustomView()
        customView.contentInsets = UIEdgeInsetsMake(30, 30, 30, 30)
        customView.backgroundColor = UIColor.lightGrayColor()
        customView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customView)
        
        xmakeConstraints { () -> Void in
            customView.xEdge =/ [80, 50, nil, -50]
            customView.xHeight =/ 200
        }
        
        let storage = customView.storage
        
        // normal text
        let text1 = NSAttributedString(string: "normal + ", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(14)])
        storage.appendAttributedString(text1)
        
        // view attachment
        let images = (0...3).map{ UIImage(named: "dog\($0)")! }
        let gifAttachment = XLYTextAttachment { () -> UIView in
            let animatedImageView = UIImageView()
            animatedImageView.backgroundColor = .purpleColor()
            animatedImageView.animationImages = images
            animatedImageView.animationDuration = 0.6
            animatedImageView.startAnimating()
            return animatedImageView
        }
        gifAttachment.bounds = CGRectMake(0, 0, 50, 50)
        let text2 = NSAttributedString(attachment: gifAttachment)
        storage.appendAttributedString(text2)
        
        // for all component in storage, we draw the outline and baseline
        let outline = XLYPainter(type: .Foreground, handler: combinePainters([strokeLineUsedRect(.redColor(), lineDashLengths:[2, 2]), strokeBaseline(.greenColor())]))
        storage.addAttribute("outline", value: outline, range: NSMakeRange(0, storage.length))
    }

}

// just an example. can be much more complicated.
public class CustomView: UIView {
    public let storage = NSTextStorage()
    public var contentInsets = UIEdgeInsetsZero
    
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
    
    public override func drawRect(rect: CGRect) {
        container.size = UIEdgeInsetsInsetRect(rect, contentInsets).size
        let origin = CGPointMake(contentInsets.left, contentInsets.top)
        let glyphRange = layoutManager.glyphRangeForCharacterRange(NSMakeRange(0, storage.length), actualCharacterRange: nil)
        layoutManager.drawBackgroundForGlyphRange(glyphRange, atPoint: origin)
        layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: origin)
    }
}
