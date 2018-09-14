//
//  XLYTextLayoutManager.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

extension CGSize {
    fileprivate var isVisible: Bool {
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
        return "\(Unmanaged.passUnretained(attachment).toOpaque())+\(charIndex)".hashValue
    }
}


// MARK: - XLYTextLayoutManager
open class XLYTextLayoutManager: NSLayoutManager {
    
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
    func attachView(for attachment: XLYTextAttachment, charIndex: Int) -> UIView? {
        return attachViews[AttachViewKey(attachment: attachment, charIndex: charIndex)]
    }
    
    func addAttachViewIfNeed(for attachment: XLYTextAttachment, charIndex: Int) {
        let key = AttachViewKey(attachment: attachment, charIndex: charIndex)
        if let viewGenerator = attachment.viewGenerator , attachViews[key] == nil {
            attachViews[key] = viewGenerator()
        }
    }
    
    func allAttachViews() -> [UIView] {
        return attachViews.map { $0.1 }
    }
    
    // MARK: - adjust attachment views
    open override func processEditing(for textStorage: NSTextStorage, edited editMask: NSTextStorage.EditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange) {
        defer {
            super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
        }
        // adjust if attachView's index has changed.
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
            attachViews.removeValue(forKey: $0)
        }
        adjustKeys.sort { $0.charIndex < $1.charIndex }
        adjustKeys.forEach {
            let view = attachViews[$0]
            view?.removeFromSuperview()
            attachViews.removeValue(forKey: $0)
            attachViews[AttachViewKey(attachment: $0.attachment, charIndex: $0.charIndex + delta)] = view
        }
    }
    
    open override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        for glyphIndex in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length) {
            let charIndex = characterIndexForGlyph(at: glyphIndex)
            
            guard let attachment = textStorage?.attribute(.attachment, at: charIndex, effectiveRange: nil) as? XLYTextAttachment else { continue }
            
            let key = AttachViewKey(attachment: attachment, charIndex: charIndex)
            let size = attachmentSize(forGlyphAt: glyphIndex)
            if attachment.canCustom && size.isVisible {
                var point = location(forGlyphAt: glyphIndex)
                let lineRect = lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
                point.x += origin.x + lineRect.origin.x
                point.y = origin.y + lineRect.minY + point.y - size.height
                let rect = CGRect(origin: point, size: size)
                if let painter = attachment.painter, let context = UIGraphicsGetCurrentContext() {
                    context.saveGState()
                    painter(context, rect)
                    context.restoreGState()
                    attachViews[key]?.removeFromSuperview()
                } else if let containerView = textContainer(forGlyphAt: glyphIndex, effectiveRange: nil)?.associatedView {
                    if let viewGenerator = attachment.viewGenerator , attachViews[key] == nil {
                        attachViews[key] = viewGenerator()
                    }
                    if let view = attachViews[key] {
                        view.frame = rect
                        containerView.addSubview(view)
                        let selectionViewClass: AnyClass? = NSClassFromString("UITextSelectionView")
                        containerView.subviews.forEach {
                            if type(of: $0).self === selectionViewClass {
                                containerView.bringSubviewToFront($0)
                            }
                        }
                        // for inner view
                        if let context = UIGraphicsGetCurrentContext(), let innerView = view as? InnerDrawView {
                            innerView.draw(in: context)
                        }
                    }
                } else {
                    attachViews[key]?.removeFromSuperview()
                }
            } else {
                attachViews[key]?.removeFromSuperview()
            }
        }
        makePaintersDraw(at: origin, type: .foreground, glyphsToShow: glyphsToShow)
    }
    
    
    // MARK: - mainly for backgroundDraw
    open override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        makePaintersDraw(at: origin, type: .background, glyphsToShow: glyphsToShow)
    }
    
    // MARK: - painter
    private func makePaintersDraw(at origin: CGPoint, type: XLYPainter.PainterType, glyphsToShow range: NSRange) {
        guard let context = UIGraphicsGetCurrentContext(), let storage = textStorage else { return }
        typealias Item = (name: NSAttributedString.Key, visualItems: [XLYVisualItem?], painter: XLYPainter)

        enumerateLineFragments(forGlyphRange: range) { (lineRect, usedRect, container, glyphRange, _) -> Void in
            let charRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let lineString = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: charRange))
            
            (0..<charRange.length).map { lineCharIndex -> [Item] in
                return lineString.attributes(at: lineCharIndex, effectiveRange: nil)
                    .filter { ($1 is XLYPainter) && ($1 as! XLYPainter).type == type }
                    .map { (name, _) -> Item in
                        var effectiveRange = NSRange()
                        let painter = lineString.attribute(name, at: lineCharIndex, longestEffectiveRange: &effectiveRange, in: NSMakeRange(0, charRange.length)) as! XLYPainter
                        lineString.removeAttribute(name, range: effectiveRange)
                        
                        effectiveRange.location += charRange.location
                        let range = self.glyphRange(forCharacterRange: effectiveRange, actualCharacterRange: nil)
                        let visualItems = (range.location..<range.location + range.length)
                            .map { glyphIndex -> XLYVisualItem? in
                                // invalid
                                var glyph: CGGlyph = 0
                                if #available(iOS 9, *) {
                                    glyph =  self.cgGlyph(at: glyphIndex)
                                } else {
                                    glyph = self.glyph(at: glyphIndex)
                                }
                                if glyph == 0
                                    || !self.boundingRect(forGlyphRange: NSMakeRange(glyphIndex, 1), in: container).size.isVisible {
                                        return nil
                                } else {
                                    var rect: CGRect = CGRect.zero, location: CGPoint, font: UIFont
                                    let attributes = storage.attributes(at: self.characterIndexForGlyph(at: glyphIndex), effectiveRange: nil)
                                    font = attributes[.font] as! UIFont
                                    let attachmentSize = self.attachmentSize(forGlyphAt: glyphIndex)
                                    if let attachment = attributes[.attachment] as? NSTextAttachment
                                        , attachmentSize.isVisible {
                                            let y = attachment.bounds.origin.y
                                            location = self.location(forGlyphAt: glyphIndex)
                                            location.y += y
                                            rect = CGRect(origin: CGPoint(x: 0, y: y), size: attachmentSize)
                                    } else {
                                        CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, &rect, 1)
                                        location = self.location(forGlyphAt: glyphIndex)
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
                .sorted { return $0.painter.zPosition < $1.painter.zPosition }
                .forEach { (name, items, painter) in
                    let visualItems = items.compactMap { ($0 != nil && $0!.rect.size.isVisible) ? $0 : nil }
                    let lineInfo = XLYLineVisualInfo(rect: lineRect.offsetBy(dx: origin.x, dy: origin.y), usedRect: usedRect.offsetBy(dx: origin.x, dy: origin.y), baseline: visualItems.first?.location.y ?? 0)
                    context.saveGState()
                    painter.handler(
                        name,
                        context,
                        lineInfo,
                        visualItems)
                    context.restoreGState()
            }
        }
    }
    
    deinit {
        attachViews.forEach { $1.removeFromSuperview() }
    }
}
