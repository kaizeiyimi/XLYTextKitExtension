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
            return responds(to: Selector(("textView"))) ? value(forKey: "textView") as? UIView : nil
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

open class XLYPainter {
    public enum PainterType {
        case background
        case foreground
    }
    
    public let type: PainterType
    public let zPosition: Int
    let handler: (_ attributeName: NSAttributedStringKey, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void
    
    public init(type: PainterType, zPosition: Int = 0, handler: @escaping (_ attributeName: NSAttributedStringKey, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void) {
        self.type = type
        self.zPosition = zPosition
        self.handler = handler
    }
}


// MARK: - XLYTextAttachment

open class XLYTextAttachment: NSTextAttachment {
    
    let viewGenerator: (() -> UIView)?
    let painter: ((_ context: CGContext, _ rect: CGRect) -> Void)?
    
    private let stringBounds: CGRect?
    
    open var canCustom: Bool {
        return image == nil && contents == nil && fileWrapper == nil
    }
    
    public init(bounds: CGRect = CGRect.zero, viewGenerator: @escaping (() -> UIView)) {
        self.viewGenerator = viewGenerator
        self.painter = nil
        self.stringBounds = nil
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }
    
    public init(bounds: CGRect = CGRect.zero, painter: @escaping (_ context: CGContext, _ rect: CGRect) -> Void) {
        self.viewGenerator = nil
        self.painter = painter
        self.stringBounds = nil
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }
    
    public enum BaseLineMode {  // negative mean move down
        case textBaseLine(diff: CGFloat)
        case lineUsedRectBottom(diff: CGFloat)
        case attachmentBottom(diff: CGFloat)
    }
    
    public init(string: NSAttributedString, lineFragmentPadding: CGFloat = 0, insets: UIEdgeInsets = UIEdgeInsets.zero, baselineMode: BaseLineMode = .textBaseLine(diff: 0), clickAction: ((NSAttributedString) -> Void)? = nil) {
        let storage = NSTextStorage(attributedString: string)
        let length = storage.length
        if length == 0 {
            self.viewGenerator = nil
            self.painter = nil
            self.stringBounds = CGRect.zero
        } else {
            var shouldUseInnerView = clickAction != nil
            if !shouldUseInnerView {
                for index in 0..<length {
                    if let attachment = storage.attribute(.attachment, at: index, effectiveRange: nil) as? XLYTextAttachment
                        , attachment.viewGenerator != nil {
                        shouldUseInnerView = true
                        break
                    }
                }
            }
            let manager = XLYTextLayoutManager()
            let container = NSTextContainer()
            container.lineFragmentPadding = lineFragmentPadding
            container.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            storage.addLayoutManager(manager)
            manager.addTextContainer(container)
            manager.ensureLayout(for: container)
            let y = manager.location(forGlyphAt: 0).y
            let usedSize = manager.usedRect(for: container).size
            if shouldUseInnerView {
                self.viewGenerator = { () -> UIView in
                    let view = InnerDrawView(storage: storage, lineFragmentPadding: lineFragmentPadding, insets: insets, clickAction: clickAction)
                    return view
                }
                self.painter = nil
            } else {
                self.viewGenerator = nil
                let glyphRange = manager.glyphRange(forCharacterRange: NSMakeRange(0, length), actualCharacterRange: nil)
                self.painter = { (context, rect) -> Void in
                    let _ = storage
                    let origin = CGPoint(x: rect.minX + insets.left, y: rect.minY + insets.top)
                    container.size = UIEdgeInsetsInsetRect(rect, insets).size
                    manager.drawBackground(forGlyphRange: glyphRange, at: origin)
                    manager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
                }
            }

            var boundsY: CGFloat
            switch baselineMode {
            case .textBaseLine(let diff):
                boundsY = y - usedSize.height - insets.bottom + diff
            case .lineUsedRectBottom(let diff):
                boundsY = -insets.bottom + diff
            case .attachmentBottom(let diff):
                boundsY = diff
            }
            stringBounds = CGRect(x: 0, y: boundsY, width: insets.left + usedSize.width + insets.right, height: insets.top + usedSize.height + insets.bottom)
        }
        
        super.init(data: nil, ofType: nil)
    }
    
    public init() {
        self.viewGenerator = nil
        self.painter = nil
        self.stringBounds = nil
        super.init(data: nil, ofType: nil)
    }
    
    override init(data contentData: Data?, ofType uti: String?) {
        self.viewGenerator = nil
        self.painter = nil
        self.stringBounds = nil
        super.init(data: contentData, ofType: uti)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.viewGenerator = nil
        self.painter = nil
        self.stringBounds = nil
        super.init(coder: aDecoder)
    }
    
    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if canCustom && viewGenerator != nil {
            if let manager = textContainer?.layoutManager as? XLYTextLayoutManager {
                manager.addAttachViewIfNeed(for: self, charIndex: charIndex)
                if let v = manager.attachView(for: self, charIndex: charIndex) {
                    if bounds.size.equalTo(CGSize.zero) {
                        v.sizeToFit()
                        return CGRect(origin: bounds.origin, size: v.frame.size)
                    }
                }
            }
        }
        return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }
    
    override open var bounds: CGRect {
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
    
    let clickAction: ((NSAttributedString) -> Void)?
    
    init(storage: NSTextStorage,
         lineFragmentPadding: CGFloat = 0,
         insets: UIEdgeInsets = UIEdgeInsets.zero,
         clickAction: ((NSAttributedString) -> Void)? = nil) {
        self.storage.append(storage)
        self.storage.addLayoutManager(manager)
        self.container.lineFragmentPadding = lineFragmentPadding
        self.manager.addTextContainer(container)
        self.insets = insets
        self.glyphRange = manager.glyphRange(forCharacterRange: NSMakeRange(0, storage.length), actualCharacterRange: nil)
        self.clickAction = clickAction
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
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
    
    func draw(in context: CGContext) {
        container.size = UIEdgeInsetsInsetRect(frame, insets).size
        let origin = CGPoint(x: frame.minX + insets.left, y: frame.minY + insets.top)
        container.associatedView = self
        manager.drawBackground(forGlyphRange: glyphRange, at: origin)
        manager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
        manager.allAttachViews().forEach {
            $0.frame = $0.frame.offsetBy(dx: -self.frame.origin.x, dy: -self.frame.origin.y)
        }
    }
    
}
