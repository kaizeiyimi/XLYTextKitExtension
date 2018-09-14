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
        let textView = UITextView(frame: CGRect.zero)
//        textView.textContainer.lineBreakMode = .ByWordWrapping
//        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.backgroundColor = UIColor.lightGray
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[v]-50-|", options: [], metrics: nil, views: ["v": textView])
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-80-[v(150)]", options: [], metrics: nil, views: ["v": textView])
        )
        
        
        textView.setUseXLYLayoutManager()
        let storage = textView.textStorage
        
        // normal text
        let text1 = NSAttributedString(string: "normal + ", attributes: [.font : UIFont.systemFont(ofSize: 14)])
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
        
        // special font
        let text3 = NSAttributedString(string: " special ", attributes: [.font : UIFont(name: "Zapfino", size: 16)!])
        storage.append(text3)
        
        // combined text
        let combined1 = NSAttributedString(string: "aa@bb.com",
            attributes: [.font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.orange,
                // add a painter for the background
                NSAttributedString.Key("combined1.background") : XLYPainter(type: .background, handler: fillLineUsedRect(color: UIColor.purple, cornerFactor: 0.5))
            ])
        let combined1Attachment = XLYTextAttachment(string: combined1,
                                                    lineFragmentPadding: 10,
                                                    insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
                                                    baselineMode: .lineUsedRectBottom(diff: 0)) { value in
                                                        print("it works! \(value.string)")
            }
        let text4 = NSMutableAttributedString(attributedString: NSAttributedString(attachment: combined1Attachment))
        // add painter for whole attachment
        text4.addAttributes([NSAttributedString.Key("combined1Attachment.background"): XLYPainter(type: .background, handler: fillIndependentGlyphRect(color: UIColor.orange))], range: NSMakeRange(0, 1))
        storage.append(text4)
        
        // combined text with view
        let combined2 = NSMutableAttributedString(string: "call@", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        combined2.append(NSAttributedString(attachment: gifAttachment))
        combined2.addAttribute(NSAttributedString.Key("combined2.background"), value: XLYPainter(type: .background, handler: fillCombinedGlyphRects(color: .orange)), range: NSMakeRange(0, combined2.length))
        let text5 = NSAttributedString(attachment: XLYTextAttachment(string: combined2, lineFragmentPadding: 0, insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), baselineMode: .textBaseLine(diff: 0)))
        storage.append(text5)
        
        
        // for all component in storage, we draw the outline and baseline
        let outline = XLYPainter(type: .foreground, handler: combinePainters([strokeOutline(color: .red, lineDashLengths:[2, 2]), strokeBaseline(color: .green)]))
        storage.addAttribute(NSAttributedString.Key("outline"), value: outline, range: NSMakeRange(0, storage.length))
    }

}

