//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

public protocol DragViewContainer {

    var draggingZOffset: NSSize { get }
    func reorder(subview: NSView, event: NSEvent)
}

private func fillHorizontal(_ subview: NSView) -> [NSLayoutConstraint] {
    return NSLayoutConstraint.constraints(
        withVisualFormat: "H:|[subview]|",
        options: [],
        metrics: nil,
        views: ["subview": subview])
}


extension DragViewContainer where Self: NSView {

    public var draggingZOffset: NSSize { return NSSize(width: 0, height: 2) }

    public func reorder(subview: NSView, event: NSEvent) {

        guard let windowContentView = window?.contentView else { preconditionFailure("Expected window with contentView") }

        let subviewFrame = convert(subview.frame, to: nil)
        let yPosition = subviewFrame.origin.y
        let initialY = event.locationInWindow.y

        let draggingView = subview.draggingView
        draggingView.frame = subviewFrame
        windowContentView.addSubview(draggingView)

        let yPositionConstraint = NSLayoutConstraint(
            item: window!.contentView!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: draggingView,
            attribute: .bottom,
            multiplier: 1,
            constant: yPosition)
        let xPositionConstraint = NSLayoutConstraint(
            item: draggingView,
            attribute: .leading,
            relatedBy: .equal,
            toItem: windowContentView,
            attribute: .leading,
            multiplier: 1,
            constant: subviewFrame.origin.x)

        let draggingViewPositionConstraints = [
            yPositionConstraint,
            xPositionConstraint
        ]
        windowContentView.addConstraints(draggingViewPositionConstraints)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true

            xPositionConstraint.constant += draggingZOffset.width
            yPositionConstraint.constant += draggingZOffset.height
            draggingView.layoutSubtreeIfNeeded()

            draggingView.layer?.shadowRadius = 3
            draggingView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        })

        subview.isHidden = true
        var previousY = initialY

        window?.trackEvents(
            matching: [.leftMouseUp, .leftMouseDragged],
            timeout: Date.distantFuture.timeIntervalSinceNow,
            mode: .eventTrackingRunLoopMode)
        { [unowned self] (dragEvent, stop) in

            guard dragEvent.type != .leftMouseUp else {

                draggingView.layoutSubtreeIfNeeded()
                let subviewFrame = self.convert(subview.frame, to: nil)
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    context.allowsImplicitAnimation = true
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

                    yPositionConstraint.constant = subviewFrame.origin.y
                    xPositionConstraint.constant = subviewFrame.origin.x
                    draggingView.layoutSubtreeIfNeeded()

                    draggingView.layer?.shadowRadius = 0
                    draggingView.layer?.shadowOffset = NSSize(width: 0, height: 0)
                }, completionHandler: {
                    draggingView.removeFromSuperview()
                    windowContentView.removeConstraints(draggingViewPositionConstraints)
                    subview.isHidden = false
                })
                stop.pointee = true
                return
            }

            self.autoscroll(with: dragEvent)

            let nextY = dragEvent.locationInWindow.y
            let draggedY = nextY - initialY
            yPositionConstraint.constant = yPosition + draggedY + self.draggingZOffset.height

            let middle      = NSMidY(self.convert(draggingView.frame, from: nil))
            let top         = NSMaxY(subview.frame)
            let bottom      = NSMinY(subview.frame)

            let movingUp    = nextY > previousY && (middle > top)
            let movingDown  = nextY < previousY && (middle < bottom)

            func moveSubview(_ direction: DragDirection) {

                self.subviews.move(subview, by: direction.offset)
                self.layoutSubviews(self.subviews)
            }

            if movingUp && subview != self.subviews.first! {
                moveSubview(.up)
            }

            if movingDown && subview != self.subviews.last! {
                moveSubview(.down)
            }

            previousY = nextY
        }
    }

    func layoutSubviews(_ subviews: [NSView]) {

        removeConstraints(self.constraints)

        if subviews.isEmpty { return }

        var prev: NSView?

        for subview in subviews {

            addConstraints(fillHorizontal(subview))
            // Constrain first item to container top;
            // Constrain all other items' top anchor to predecessor's bottom anchor.
            addConstraint(
                NSLayoutConstraint(
                    item:       subview,
                    attribute:  .top,
                    relatedBy:  .equal,
                    toItem:     prev != nil ? prev!     : self,
                    attribute:  prev != nil ? .bottom   : .top,
                    multiplier: 1,
                    constant:   prev != nil ? 1         : 0)
            )
            prev = subview
        }

        // Constrain last item to container bottom
        addConstraint(NSLayoutConstraint(
            item: prev!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1,
            constant: 0)
        )
    }
}

enum DragDirection {
    case up, down

    var offset: Int {
        switch self {
        case .up:   return -1
        case .down: return 1
        }
    }
}