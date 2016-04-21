//
//  XLYTextLayoutManager.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

extension CGSize {
    private var isVisible: Bool {
        return width > 0 && height > 0
    }
}

private struct AssociatedKeys {
    static var XLYTextLayoutManagerAttachViewsKey = "XLYTextLayoutManagerAttachViews.Key"
}

private func ==(lhs: AttachViewKey, rhs: AttachViewKey) -> Bool {
    return lhs.attachment == rhs.attachment && lhs.charIndex == rhs.charIndex
}

private final class AttachViewKey: Hashable {
    let attachment: NSTextAttachment
    let charIndex: Int
    init (attachment: NSTextAttachment, charIndex: Int) {
        self.attachment = attachment
        self.charIndex = charIndex
    }
    
    var hashValue: Int {
        return "\(unsafeAddressOf(attachment))+\(charIndex)".hashValue
    }
}


// MARK: - XLYTextLayoutManager
public class XLYTextLayoutManager: NSLayoutManager {
    
    private var attachViews: [AttachViewKey: UIView] {
        get {
            if objc_getAssociatedObject(self, &AssociatedKeys.XLYTextLayoutManagerAttachViewsKey) == nil {
                self.attachViews = [:]
            }
            return objc_getAssociatedObject(self, &AssociatedKeys.XLYTextLayoutManagerAttachViewsKey) as! [AttachViewKey: UIView]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.XLYTextLayoutManagerAttachViewsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    //
    func attachView(attachment: XLYTextAttachment, charIndex: Int) -> UIView? {
        return attachViews[AttachViewKey(attachment: attachment, charIndex: charIndex)]
    }
    
    func addAttachViewForAttachmentIfNeed(attachment: XLYTextAttachment, charIndex: Int) {
        let key = AttachViewKey(attachment: attachment, charIndex: charIndex)
        if let viewGenerator = attachment.viewGenerator where attachViews[key] == nil {
            attachViews[key] = viewGenerator()
        }
    }
    
    func allAttachView() -> [UIView] {
        return attachViews.map { $0.1 }
    }
    
    // MARK: - adjust attachment views
    public override func processEditingForTextStorage(textStorage: NSTextStorage, edited editMask: NSTextStorageEditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange) {
        defer {
            super.processEditingForTextStorage(textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
        }
        // adjust if attachView's index has changed.
        guard delta != 0 else { return }
        let oldRange = newCharRange.location..<(newCharRange.location + newCharRange.length - delta)
        var deleteKeys = [AttachViewKey](), adjustKeys = [AttachViewKey]()
        for key in attachViews.keys {
            switch key.charIndex {
            case oldRange:
                deleteKeys.append(key)
            case let index where index >= oldRange.endIndex:
                adjustKeys.append(key)
            default:
                break
            }
        }
        deleteKeys.forEach {
            attachViews[$0]?.removeFromSuperview()
            attachViews.removeValueForKey($0)
        }
        adjustKeys.sortInPlace { $0.0.charIndex < $0.1.charIndex }
        adjustKeys.forEach {
            let view = attachViews[$0]
            attachViews.removeValueForKey($0)
            attachViews[AttachViewKey(attachment: $0.attachment, charIndex: $0.charIndex + delta)] = view
        }
    }
    
    override public func drawGlyphsForGlyphRange(glyphsToShow: NSRange, atPoint origin: CGPoint) {
        super.drawGlyphsForGlyphRange(glyphsToShow, atPoint: origin)
        for glyphIndex in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length) {
            let charIndex = characterIndexForGlyphAtIndex(glyphIndex)
            
            guard let attachment = textStorage?.attribute(NSAttachmentAttributeName, atIndex: charIndex, effectiveRange: nil) as? XLYTextAttachment else { continue }
            
            let key = AttachViewKey(attachment: attachment, charIndex: charIndex)
            let size = attachmentSizeForGlyphAtIndex(glyphIndex)
            if attachment.canCustom && size.isVisible {
                var point = locationForGlyphAtIndex(glyphIndex)
                let lineRect = lineFragmentRectForGlyphAtIndex(glyphIndex, effectiveRange: nil)
                point.x += origin.x + lineRect.origin.x
                point.y = origin.y + lineRect.minY + point.y - size.height
                let rect = CGRect(origin: point, size: size)
                if let painter = attachment.painter, context = UIGraphicsGetCurrentContext() {
                    CGContextSaveGState(context)
                    painter(context: context, rect: rect)
                    CGContextRestoreGState(context)
                    attachViews[key]?.removeFromSuperview()
                } else if let containerView = textContainerForGlyphAtIndex(glyphIndex, effectiveRange: nil)?.associatedView {
                    if let viewGenerator = attachment.viewGenerator where attachViews[key] == nil {
                        attachViews[key] = viewGenerator()
                    }
                    if let view = attachViews[key] {
                        view.frame = rect
                        containerView.addSubview(view)
                        let type: AnyClass? = NSClassFromString("UITextSelectionView")
                        containerView.subviews.forEach {
                            if $0.dynamicType.self === type {
                                containerView.bringSubviewToFront($0)
                            }
                        }
                        // for inner view
                        if let context = UIGraphicsGetCurrentContext(), innerView = view as? InnerDrawView {
                            innerView.draw(context, view: containerView)
                        }
                    }
                } else {
                    attachViews[key]?.removeFromSuperview()
                }
            } else {
                attachViews[key]?.removeFromSuperview()
            }
        }
        makePaintersDraw(.Foreground, glyphsToShow: glyphsToShow, atPoint: origin)
    }
    
    
    // MARK: - mainly for backgroundDraw
    public override func drawBackgroundForGlyphRange(glyphsToShow: NSRange, atPoint origin: CGPoint) {
        super.drawBackgroundForGlyphRange(glyphsToShow, atPoint: origin)
        makePaintersDraw(.Background, glyphsToShow: glyphsToShow, atPoint: origin)
    }
    
    // MARK: - painter
    private func makePaintersDraw(painterType: XLYPainter.PainterType, glyphsToShow: NSRange, atPoint origin: CGPoint) {
        guard let context = UIGraphicsGetCurrentContext(), storage = textStorage else { return }
        typealias Item = (name: String, visualItems: [XLYVisualItem?], painter: XLYPainter)

        enumerateLineFragmentsForGlyphRange(glyphsToShow) { (lineRect, usedRect, container, glyphRange, _) -> Void in
            let charRange = self.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
            let lineString = NSMutableAttributedString(attributedString: storage.attributedSubstringFromRange(charRange))
            
            (0..<charRange.length).map { lineCharIndex -> [Item] in
                return lineString.attributesAtIndex(lineCharIndex, effectiveRange: nil)
                    .filter { ($1 is XLYPainter) && ($1 as! XLYPainter).type == painterType }
                    .map { (name, _) -> Item in
                        var effectiveRange = NSRange()
                        let painter = lineString.attribute(name, atIndex: lineCharIndex, longestEffectiveRange: &effectiveRange, inRange: NSMakeRange(0, charRange.length)) as! XLYPainter
                        lineString.removeAttribute(name, range: effectiveRange)
                        
                        effectiveRange.location += charRange.location
                        let visualItems = self.glyphRangeForCharacterRange(effectiveRange, actualCharacterRange: nil).toRange()!
                            .map { glyphIndex -> XLYVisualItem? in
                                // invalid
                                var glyph: CGGlyph = 0
                                if #available(iOS 9, *) {
                                    glyph =  self.CGGlyphAtIndex(glyphIndex)
                                } else {
                                    glyph = self.glyphAtIndex(glyphIndex)
                                }
                                if glyph == 0
                                    || !self.boundingRectForGlyphRange(NSMakeRange(glyphIndex, 1), inTextContainer: container).size.isVisible {
                                        return nil
                                } else {
                                    var rect: CGRect = CGRectZero, location: CGPoint, font: UIFont
                                    let attributes = storage.attributesAtIndex(self.characterIndexForGlyphAtIndex(glyphIndex), effectiveRange: nil)
                                    font = attributes[NSFontAttributeName] as! UIFont
                                    let attachmentSize = self.attachmentSizeForGlyphAtIndex(glyphIndex)
                                    if let attachment = attributes[NSAttachmentAttributeName] as? NSTextAttachment
                                        where attachmentSize.isVisible {
                                            let y = attachment.bounds.origin.y
                                            location = self.locationForGlyphAtIndex(glyphIndex)
                                            location.y += y
                                            rect = CGRect(origin: CGPointMake(0, y), size: attachmentSize)
                                    } else {
                                        CTFontGetBoundingRectsForGlyphs(font, .Default, &glyph, &rect, 1)
                                        location = self.locationForGlyphAtIndex(glyphIndex)
                                    }
                                    
                                    location.x += origin.x
                                    location.y += origin.y + lineRect.minY
                                    rect.origin.x += location.x
                                    rect.origin.y = location.y - rect.origin.y - rect.height
                                    return XLYVisualItem(rect: rect, location: location, glyph: glyph, font: font)
                                }
                        }
                        return (name: name, visualItems: visualItems, painter: painter)
                }
                }.flatMap { $0 }
                .sort { return $0.0.painter.zPosition < $0.1.painter.zPosition }
                .forEach { (name, items, painter) in
                    let visualItems = items.flatMap { ($0 != nil && $0!.rect.size.isVisible) ? $0 : nil }
                    let lineInfo = XLYLineVisualInfo(rect: lineRect.offsetBy(dx: origin.x, dy: origin.y), usedRect: usedRect.offsetBy(dx: origin.x, dy: origin.y), baseline: visualItems.first?.location.y ?? 0)
                    CGContextSaveGState(context)
                    painter.handler(
                        attributeName: name,
                        context: context,
                        lineInfo: lineInfo,
                        visualItems: visualItems)
                    CGContextRestoreGState(context)
            }
        }
    }
    
    deinit {
        attachViews.forEach { $1.removeFromSuperview() }
    }
}
