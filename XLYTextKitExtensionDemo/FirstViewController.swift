//
//  FirstViewController.swift
//  XLYTextKitExtensionDemo
//
//  Created by kaizei on 16/1/6.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYTextKitExtension


class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UITextView
        let textView = UITextView(frame: CGRectZero)
//        textView.textContainer.lineBreakMode = .ByWordWrapping
//        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        textView.backgroundColor = UIColor.lightGrayColor()
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activateConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-50-[v]-50-|", options: [], metrics: nil, views: ["v": textView])
        )
        NSLayoutConstraint.activateConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-80-[v(150)]", options: [], metrics: nil, views: ["v": textView])
        )
        
        
        textView.setUseXLYLayoutManager()
        let storage = textView.textStorage
        
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
        
        // special font
        let text3 = NSAttributedString(string: " special ", attributes: [NSFontAttributeName : UIFont(name: "Zapfino", size: 16)!])
        storage.appendAttributedString(text3)
        
        // combined text
        let combined1 = NSAttributedString(string: "aa@bb.com",
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16),
                NSForegroundColorAttributeName: UIColor.orangeColor(),
                // add a painter for the background
                "combined1.background": XLYPainter(type: .Background, handler: fillLineUsedRect(UIColor.purpleColor(), cornerFactor: 0.5))
            ])
        let combined1Attachment = XLYTextAttachment(string: combined1,
                                                    lineFragmentPadding: 10,
                                                    insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
                                                    baselineMode: .LineUsedRectBottom(diff: 0)) { value in
                                                        print("it works! \(value.string)")
            }
        let text4 = NSMutableAttributedString(attributedString: NSAttributedString(attachment: combined1Attachment))
        // add painter for whole attachment
        text4.addAttributes(["combined1Attachment.background": XLYPainter(type: .Background, handler: fillIndependentGlyphRect(UIColor.orangeColor()))], range: NSMakeRange(0, 1))
        storage.appendAttributedString(text4)
        
        // combined text with view
        let combined2 = NSMutableAttributedString(string: "call@", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16)])
        combined2.appendAttributedString(NSAttributedString(attachment: gifAttachment))
        combined2.addAttribute("combined2.background", value: XLYPainter(type: .Background, handler: fillCombinedGlyphRects(.orangeColor())), range: NSMakeRange(0, combined2.length))
        let text5 = NSAttributedString(attachment: XLYTextAttachment(string: combined2, lineFragmentPadding: 0, insets: UIEdgeInsetsMake(5, 5, 5, 5), baselineMode: .TextBaseLine(diff: 0)))
        storage.appendAttributedString(text5)
        
        
        // for all component in storage, we draw the outline and baseline
        let outline = XLYPainter(type: .Foreground, handler: combinePainters([strokeOutline(.redColor(), lineDashLengths:[2, 2]), strokeBaseline(.greenColor())]))
        storage.addAttribute("outline", value: outline, range: NSMakeRange(0, storage.length))
    }

}

