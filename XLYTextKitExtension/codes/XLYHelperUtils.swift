//
//  Utils.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

// MARK: - helper. all are curried functions for XLYPainter.
public func combinePainters(_ handlers: [(NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void])
     -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (attributeName: NSAttributedStringKey, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            handlers.forEach {
                context.saveGState()
                $0(attributeName, context, lineInfo, visualItems)
                context.restoreGState()
            }
        }
}

public func strokeBaseline(color: UIColor, width: CGFloat = 1)
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, lineInfo, _) in
            color.setStroke()
            context.setLineWidth(width)
            context.move(to: CGPoint(x: lineInfo.usedRect.minX, y: lineInfo.baseline))
            context.addLine(to: CGPoint(x: lineInfo.usedRect.maxX, y: lineInfo.baseline))
            context.drawPath(using: .stroke)
        }
}

public func strokeOutline(color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
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
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
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
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, lineInfo, _) in
            color.setFill()
            let rect = UIEdgeInsetsInsetRect(lineInfo.usedRect, insets)
            let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
            context.addPath(path.cgPath)
            context.fillPath()
        }
}

public func fillCombinedGlyphRects(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, _, visualItems) in
            if visualItems.count >= 1 {
                let rect = visualItems.suffix(from: 1).reduce(visualItems.first!.rect) {
                    return $0.union($1.rect)
                }
                color.setFill()
                let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
                let path = UIBezierPath(roundedRect: UIEdgeInsetsInsetRect(rect, insets), cornerRadius: corner)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
}

public func fillIndependentGlyphRect(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (NSAttributedStringKey, CGContext, XLYLineVisualInfo, [XLYVisualItem]) -> Void {
        return { (_, context, _, visualItems) in
            color.setFill()
            visualItems.forEach {
                let rect = UIEdgeInsetsInsetRect($0.rect, insets)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerFactor == nil ? corner : rect.height * cornerFactor!)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
}
