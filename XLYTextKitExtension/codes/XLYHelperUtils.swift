//
//  Utils.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

// MARK: - helper. all are curried functions for XLYPainter.
public func combinePainters(_ handlers: [(NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void])
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (attributeName: NSAttributedString.Key, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            handlers.forEach {
                context.saveGState()
                $0(attributeName, context, lineInfo, visualItems)
                context.restoreGState()
            }
        }
}

public func strokeBaseline(color: UIColor, width: CGFloat = 1)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, lineInfo, _) in
            color.setStroke()
            context.setLineWidth(width)
            context.move(to: CGPoint(x: lineInfo.usedRect.minX, y: lineInfo.baseline))
            context.addLine(to: CGPoint(x: lineInfo.usedRect.maxX, y: lineInfo.baseline))
            context.drawPath(using: .stroke)
        }
}

public func strokeOutline(color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, _, visualItems) in
            color.setStroke()
            if let lengths = lineDashLengths , lengths.count > 0 {
                context.setLineDash(phase: 0, lengths: lengths)
            }
            visualItems.forEach {
                context.stroke($0.rect)
            }
        }
}

public func strokeLineUsedRect(color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, lineInfo, _) in
            color.setStroke()
            context.setLineWidth(width)
            if let lengths = lineDashLengths , lengths.count > 0 {
                context.setLineDash(phase: 0, lengths: lengths)
            }
            context.stroke(lineInfo.usedRect)
        }
}


public func fillLineUsedRect(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, lineInfo, _) in
            color.setFill()
            let rect = lineInfo.usedRect.inset(by: insets)
            let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
            context.addPath(path.cgPath)
            context.fillPath()
        }
}

public func fillCombinedGlyphRects(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, _, visualItems) in
            if visualItems.count >= 1 {
                let rect = visualItems.suffix(from: 1).reduce(visualItems.first!.rect) {
                    return $0.union($1.rect)
                }
                color.setFill()
                let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
                let path = UIBezierPath(roundedRect: rect.inset(by: insets), cornerRadius: corner)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
}

public func fillIndependentGlyphRect(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (NSAttributedString.Key, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, _, visualItems) in
            color.setFill()
            visualItems.forEach {
                let rect = $0.rect.inset(by: insets)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerFactor == nil ? corner : rect.height * cornerFactor!)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
}


public final class StaticWrappableContainerView: UIView {
    private let textView = UITextView()
    private var views: [(UIView, CGFloat)] = []
    private var rightConstraint: NSLayoutConstraint!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        textView.setUseXLYLayoutManager()
        textView.isScrollEnabled = false
        if #available(iOS 11, *) {
            textView.textDragInteraction?.isEnabled = false
        }
        textView.isEditable = false
        textView.isSelectable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        textView.clipsToBounds = true
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        rightConstraint = textView.rightAnchor.constraint(equalTo: self.rightAnchor)
        rightConstraint.isActive = true
    }
    
    public func reset(_ views: [UIView], itemSpace: CGFloat = 0, lineSpace: CGFloat = 0) {
        self.views = views.map { view in
            let box = UIView()
            let size: CGSize
            if view.translatesAutoresizingMaskIntoConstraints {
                view.sizeToFit()
                size = view.frame.size
                view.frame = CGRect(origin: .zero, size: size)
                box.frame = CGRect(x: 0, y: 0, width: size.width + itemSpace, height: size.height)
                box.addSubview(view)
            } else {
                size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .fittingSizeLevel)
                box.addSubview(view)
                view.topAnchor.constraint(equalTo: box.topAnchor).isActive = true
                view.leftAnchor.constraint(equalTo: box.leftAnchor).isActive = true
                box.frame = CGRect(x: 0, y: 0, width: size.width + itemSpace, height: size.height)
            }
            return (box, size.width)
        }
        
        let attrText = self.views.map{ (view, _) -> NSAttributedString in
            NSAttributedString(attachment: XLYTextAttachment(bounds: view.frame, viewGenerator: { view }))
        }.reduce(into: NSMutableAttributedString(), { $0.append($1) })
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpace
        paragraphStyle.baseWritingDirection = .leftToRight
        attrText.addAttributes([.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attrText.length))
        textView.textStorage.setAttributedString(attrText)
    }
}

