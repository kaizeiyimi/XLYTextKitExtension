//
//  FirstViewController.swift
//  XLYTextKitExtensionDemo
//
//  Created by kaizei on 16/1/6.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit
import XLYTextKitExtension
import XAutoLayout


class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UITextView
        let textView = UITextView(frame: CGRectZero)
        textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
        textView.backgroundColor = UIColor.lightGrayColor()
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        xmakeConstraints { () -> Void in
            textView.xEdge =/ [80, 50, nil, -50]
            textView.xHeight =/ 200
        }
        
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
                "combined1.background": XLYPainter(type: .Background, handler: { (attributeName, context, lineInfo, visualItems) -> Void in
                    let path = UIBezierPath(roundedRect: lineInfo.usedRect, cornerRadius: lineInfo.usedRect.height / 2)
                    CGContextAddPath(context, path.CGPath)
                    UIColor.purpleColor().setFill()
                    CGContextFillPath(context)
                })
            ])
        let combined1Attachment = XLYTextAttachment(string: combined1, lineFragment: 10, insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        let text4 = NSMutableAttributedString(attributedString: NSAttributedString(attachment: combined1Attachment))
        // add painter for whole attachment
        text4.addAttributes(["combined1Attachment.background": XLYPainter(type: .Background, handler: { (attributeName, context, lineInfo, visualItems) -> Void in
            UIColor.orangeColor().setFill()
            visualItems.forEach {
                CGContextFillRect(context, $0.rect)
            }
        })], range: NSMakeRange(0, 1))
        storage.appendAttributedString(text4)
        
        // combined text with view
        let combined2 = NSMutableAttributedString(string: "call@", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16)])
        combined2.appendAttributedString(NSAttributedString(attachment: gifAttachment))
        combined2.addAttribute("combined2.background", value: XLYPainter(type: .Background, handler: { (attributeName, context, lineInfo, visualItems) -> Void in
            if visualItems.count >= 1 {
                let rect = visualItems.suffixFrom(1).reduce(visualItems.first!.rect) {
                    return $0.union($1.rect)
                }
                UIColor.orangeColor().setFill()
                CGContextFillRect(context, rect)
            }
            
        }), range: NSMakeRange(0, combined2.length))
        let text5 = NSAttributedString(attachment: XLYTextAttachment(string: combined2, lineFragment: 0, insets: UIEdgeInsetsMake(5, 5, 5, 5)))
        storage.appendAttributedString(text5)
        
        
        // for all component in storage, we draw the outline
        let outline = XLYPainter(type: .Foreground) { (attributeName, context, lineInfo, visualItems) -> Void in
            UIColor.redColor().setStroke()
            visualItems.forEach {
                CGContextStrokeRectWithWidth(context, $0.rect, 1)
            }
            if let baseline = visualItems.first?.location.y {
                UIColor.greenColor().setStroke()
                CGContextSetLineWidth(context, 1)
                CGContextMoveToPoint(context, lineInfo.usedRect.minX, baseline)
                CGContextAddLineToPoint(context, lineInfo.usedRect.maxX, baseline)
                CGContextDrawPath(context, .Stroke)
            }
        }
        
        storage.addAttribute("outline", value: outline, range: NSMakeRange(0, storage.length))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

