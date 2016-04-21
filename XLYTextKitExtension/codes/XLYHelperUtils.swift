//
//  Utils.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

// MARK: - helper. all are curried functions for XLYPainter.
public func combinePainters(handlers: [(attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void])
     -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            handlers.forEach {
                CGContextSaveGState(context)
                $0(attributeName: attributeName, context: context, lineInfo: lineInfo, visualItems: visualItems)
                CGContextRestoreGState(context)
            }
        }
}

public func strokeBaseline(color: UIColor, width: CGFloat = 1)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            CGContextSetLineWidth(context, width)
            CGContextMoveToPoint(context, lineInfo.usedRect.minX, lineInfo.baseline)
            CGContextAddLineToPoint(context, lineInfo.usedRect.maxX, lineInfo.baseline)
            CGContextDrawPath(context, .Stroke)
        }
}

public func strokeOutline(color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            if let lengths = lineDashLengths where lengths.count > 0 {
                CGContextSetLineDash(context, 0, lengths, lengths.count)
            }
            visualItems.forEach {
                CGContextStrokeRect(context, $0.rect)
            }
        }
}

public func strokeLineUsedRect(color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            CGContextSetLineWidth(context, width)
            if let lengths = lineDashLengths where lengths.count > 0 {
                CGContextSetLineDash(context, 0, lengths, lengths.count)
            }
            CGContextStrokeRect(context, lineInfo.usedRect)
        }
}


public func fillLineUsedRect(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsetsZero)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setFill()
            let rect = UIEdgeInsetsInsetRect(lineInfo.usedRect, insets)
            let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
            CGContextAddPath(context, path.CGPath)
            CGContextFillPath(context)
        }
}

public func fillCombinedGlyphRects(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsetsZero)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            if visualItems.count >= 1 {
                let rect = visualItems.suffixFrom(1).reduce(visualItems.first!.rect) {
                    return $0.union($1.rect)
                }
                color.setFill()
                let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
                let path = UIBezierPath(roundedRect: UIEdgeInsetsInsetRect(rect, insets), cornerRadius: corner)
                CGContextAddPath(context, path.CGPath)
                CGContextFillPath(context)
            }
        }
}

public func fillIndependentGlyphRect(color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsetsZero)
    -> (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setFill()
            visualItems.forEach {
                let rect = UIEdgeInsetsInsetRect($0.rect, insets)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerFactor == nil ? corner : rect.height * cornerFactor!)
                CGContextAddPath(context, path.CGPath)
                CGContextFillPath(context)
            }
        }
}
