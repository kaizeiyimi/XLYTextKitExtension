//
//  Utils.swift
//
//  Created by kaizei on 15/12/10.
//  Copyright © 2015年 kaizei. All rights reserved.
//

import Foundation

// MARK: - helper. all are curried functions for XLYPainter.
public func combinePainters(_ handlers: [(_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void])
     -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            handlers.forEach {
                context.saveGState()
                $0(attributeName, context, lineInfo, visualItems)
                context.restoreGState()
            }
        }
}

public func strokeBaseline(_ color: UIColor, width: CGFloat = 1)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            context.setLineWidth(width)
            context.move(to: CGPoint(x: lineInfo.usedRect.minX, y: lineInfo.baseline))
            context.addLine(to: CGPoint(x: lineInfo.usedRect.maxX, y: lineInfo.baseline))
            context.drawPath(using: .stroke)
        }
}

public func strokeOutline(_ color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            if let lengths = lineDashLengths , lengths.count > 0 {
                context.setLineDash(phase: 0, lengths: lengths)
            }
            visualItems.forEach {
                context.stroke($0.rect)
            }
        }
}

public func strokeLineUsedRect(_ color: UIColor, width: CGFloat = 1, lineDashLengths:[CGFloat]? = nil)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setStroke()
            context.setLineWidth(width)
            if let lengths = lineDashLengths , lengths.count > 0 {
                context.setLineDash(phase: 0, lengths: lengths)
            }
            context.stroke(lineInfo.usedRect)
        }
}


public func fillLineUsedRect(_ color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setFill()
            let rect = UIEdgeInsetsInsetRect(lineInfo.usedRect, insets)
            let corner = cornerFactor.flatMap { $0 * rect.height } ?? corner
            let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
            context.addPath(path.cgPath)
            context.fillPath()
        }
}

public func fillCombinedGlyphRects(_ color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
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

public func fillIndependentGlyphRect(_ color: UIColor, corner: CGFloat = 0, cornerFactor: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero)
    -> (_ attributeName: String, _ context: CGContext, _ lineInfo: XLYLineVisualInfo, _ visualItems: [XLYVisualItem]) -> Void {
        return { (attributeName: String, context: CGContext, lineInfo: XLYLineVisualInfo, visualItems: [XLYVisualItem]) in
            color.setFill()
            visualItems.forEach {
                let rect = UIEdgeInsetsInsetRect($0.rect, insets)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerFactor == nil ? corner : rect.height * cornerFactor!)
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
}
