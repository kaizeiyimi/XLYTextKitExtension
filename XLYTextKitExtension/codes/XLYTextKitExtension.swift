//
//  XLYTextExtension.swift
//
//  Created by kaizei on 15/12/4.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import UIKit

private struct AssociatedKeys {
    static var XLYTextContainerAssociatedViewKey = "XLYTextContainerAssociatedView.Key"
}

// MARK: - extension NSTextContainer

extension NSTextContainer {
    public var associatedView: UIView? {
        get {
            if let view = objc_getAssociatedObject(self, &AssociatedKeys.XLYTextContainerAssociatedViewKey) as? UIView {
                return view
            }
            return valueForKey("textView") as? UIView
        }
        set {
          objc_setAssociatedObject(self, &AssociatedKeys.XLYTextContainerAssociatedViewKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}


// MARK: - extension UITextView
extension UITextView {
    public func setUseXLYLayoutManager() {
        object_setClass(layoutManager, XLYTextLayoutManager.self)
    }
    
    @IBInspectable
    @objc private var useXLYLayoutManager: Bool {
        get { return false }
        set {
            if newValue {
                setUseXLYLayoutManager()
            }
        }
    }
}

// MARK: - XLYPainter

public struct XLYVisualItem {
    public let rect: CGRect
    public let location: CGPoint
    public let glyph: CGGlyph
    public let font: UIFont
}

public struct XLYLineVisualInfo {
    public let rect: CGRect
    public let usedRect: CGRect
    public let baseline: CGFloat
}

public class XLYPainter {
    public enum PainterType {
        case Background
        case Foreground
    }
    
    public let type: PainterType
    public private(set) var zPosition: Int = 0
    let handler: (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void
    
    public init(type: PainterType, zPosition: Int = 0, handler: (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void) {
        self.type = type
        self.zPosition = zPosition
        self.handler = handler
    }
}


// MARK: - XLYTextAttachment

public class XLYTextAttachment: NSTextAttachment {
    
    let viewGenerator: (() -> UIView)?
    let painter: ((context: CGContext, rect: CGRect) -> Void)?
    
    private var stringBounds: CGRect?
    
    public var canCustom: Bool {
        return image == nil && contents == nil && fileWrapper == nil
    }
    
    @NSCopying public private(set) var associatedAttrString: NSAttributedString?
    
    public init(bounds: CGRect = CGRectZero, viewGenerator: (() -> UIView)) {
        self.viewGenerator = viewGenerator
        painter = nil
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }
    
    public init(bounds: CGRect = CGRectZero, painter: (context: CGContext, rect: CGRect) -> Void) {
        self.viewGenerator = nil
        self.painter = painter
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }
    
    public enum BaseLineMode {  // negative mean move down
        case TextBaseLine(diff: CGFloat)
        case LineUsedRectBottom(diff: CGFloat)
        case AttachmentBottom(diff: CGFloat)
    }
    
    public convenience init(string: NSAttributedString, lineFragmentPadding: CGFloat = 0, insets: UIEdgeInsets = UIEdgeInsetsZero, baselineMode: BaseLineMode = .TextBaseLine(diff: 0), clickAction: (NSAttributedString -> Void)? = nil) {
        let storage = NSTextStorage(attributedString: string)
        let length = storage.length
        if length == 0 {
            self.init()
            stringBounds = CGRectZero
        } else {
            var shouldUseInnerView = clickAction != nil
            if !shouldUseInnerView {
                for index in 0..<length {
                    if let attachment = storage.attribute(NSAttachmentAttributeName, atIndex: index, effectiveRange: nil) as? XLYTextAttachment
                        where attachment.viewGenerator != nil {
                        shouldUseInnerView = true
                        break
                    }
                }
            }
            let manager = XLYTextLayoutManager()
            let container = NSTextContainer()
            container.lineFragmentPadding = lineFragmentPadding
            container.size = CGSizeMake(CGFloat.max, CGFloat.max)
            storage.addLayoutManager(manager)
            manager.addTextContainer(container)
            manager.ensureLayoutForTextContainer(container)
            let y = manager.locationForGlyphAtIndex(0).y
            let usedSize = manager.usedRectForTextContainer(container).size
            if shouldUseInnerView {
                self.init { () -> UIView in
                    let view = InnerDrawView(storage: storage, lineFragmentPadding: lineFragmentPadding, insets: insets, clickAction: clickAction)
                    return view
                }
            } else {
                let glyphRange = manager.glyphRangeForCharacterRange(NSMakeRange(0, length), actualCharacterRange: nil)
                self.init(painter: { (context, rect) -> Void in
                    let _ = storage
                    let origin = CGPointMake(rect.minX + insets.left, rect.minY + insets.top)
                    container.size = UIEdgeInsetsInsetRect(rect, insets).size
                    manager.drawBackgroundForGlyphRange(glyphRange, atPoint: origin)
                    manager.drawGlyphsForGlyphRange(glyphRange, atPoint: origin)
                })
            }
            associatedAttrString = string
            var boundsY: CGFloat
            switch baselineMode {
            case .TextBaseLine(let diff):
                boundsY = y - usedSize.height - insets.bottom + diff
            case .LineUsedRectBottom(let diff):
                boundsY = -insets.bottom + diff
            case .AttachmentBottom(let diff):
                boundsY = diff
            }
            stringBounds = CGRectMake(0, boundsY, insets.left + usedSize.width + insets.right, insets.top + usedSize.height + insets.bottom)
        }
    }
    
    public init() {
        viewGenerator = nil
        painter = nil
        super.init(data: nil, ofType: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        viewGenerator = nil
        painter = nil
        super.init(coder: aDecoder)
    }
    
    override public func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if canCustom && viewGenerator != nil {
            if let manager = textContainer?.layoutManager as? XLYTextLayoutManager {
                manager.addAttachViewForAttachmentIfNeed(self, charIndex: charIndex)
                if let v = manager.attachView(self, charIndex: charIndex) {
                    if CGSizeEqualToSize(bounds.size, CGSizeZero) {
                        v.sizeToFit()
                        return CGRect(origin: bounds.origin, size: v.frame.size)
                    }
                }
            }
        }
        return super.attachmentBoundsForTextContainer(textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }
    
    override public var bounds: CGRect {
        get {
            return (canCustom && stringBounds != nil) ? stringBounds! : super.bounds
        }
        set {
            super.bounds = newValue
        }
    }
}

// MARK: - InnerDrawView. for embed draw

final class InnerDrawView: UIView {
    let storage = NSTextStorage()
    let manager = XLYTextLayoutManager()
    let container = NSTextContainer()
    
    let glyphRange: NSRange
    let insets: UIEdgeInsets
    
    let clickAction: (NSAttributedString -> Void)?
    
    override var backgroundColor: UIColor? {
        didSet {
            print(backgroundColor)
        }
    }
    
    init(storage: NSTextStorage,
         lineFragmentPadding: CGFloat = 0,
         insets: UIEdgeInsets = UIEdgeInsetsZero,
         clickAction: (NSAttributedString -> Void)? = nil) {
        self.storage.appendAttributedString(storage)
        self.storage.addLayoutManager(manager)
        self.container.lineFragmentPadding = lineFragmentPadding
        self.manager.addTextContainer(container)
        self.insets = insets
        self.glyphRange = manager.glyphRangeForCharacterRange(NSMakeRange(0, storage.length), actualCharacterRange: nil)
        self.clickAction = clickAction
        super.init(frame: CGRectZero)
        backgroundColor = UIColor.clearColor()
        if clickAction != nil {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:))))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onTap(_: AnyObject) {
        clickAction?(storage)
    }
    
    func draw(context: CGContext, view: UIView) {
        container.size = UIEdgeInsetsInsetRect(frame, insets).size
        let origin = CGPointMake(frame.minX + insets.left, frame.minY + insets.top)
        container.associatedView = self
        manager.drawBackgroundForGlyphRange(glyphRange, atPoint: origin)
        manager.drawGlyphsForGlyphRange(glyphRange, atPoint: origin)
        manager.allAttachView().forEach {
            $0.frame = $0.frame.offsetBy(dx: -self.frame.origin.x, dy: -self.frame.origin.y)
        }
    }
    
}
