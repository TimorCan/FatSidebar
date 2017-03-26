//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

extension NSSize {
    init(quadratic width: CGFloat) {
        self.init(width: width, height: width)
    }
}

@IBDesignable
public class FatSidebar: NSView {

    // MARK: - Content

    fileprivate var items: [FatSidebarItem] = [] {
        didSet {
            layoutItems()
        }
    }

    public var itemCount: Int {
        return items.count
    }

    public func item(at index: Int) -> FatSidebarItem? {

        return items[safe: index]
    }

    public func contains(_ item: FatSidebarItem) -> Bool {

        return items.contains(item)
    }


    // MARK: Insertion

    @discardableResult
    public func appendItem(title: String, callback: @escaping (FatSidebarItem) -> Void) -> FatSidebarItem {

        let item = FatSidebarItem(
            title: title,
            callback: callback)

        items.append(item)
        addSubview(item)

        return item
    }

    /// - returns: `nil` if `item` is not part of this sidebar, an instance of `FatSidebarItem` otherwise.
    @discardableResult
    public func insertItem(after item: FatSidebarItem, title: String, callback: @escaping (FatSidebarItem) -> Void) -> FatSidebarItem? {

        guard let index = items.index(where: { $0 === item }) else { return nil }

        let item = FatSidebarItem(
            title: title,
            callback: callback)

        items.insert(item, at: index + 1)
        addSubview(item)

        return item
    }

    // MARK: Removal

    @discardableResult
    public func removeAllItems() -> [FatSidebarItem] {

        let removedItems = items
        items.removeAll()
        removedItems.forEach { $0.removeFromSuperview() }
        return removedItems
    }

    // MARK: Selection

    @discardableResult
    public func selectItem(_ item: FatSidebarItem) -> Bool {

        guard self.contains(item) else { return false }

        for existingItem in items {
            existingItem.isSelected = (existingItem === item)
        }

        return true
    }

    @discardableResult
    public func deselectItem(_ item: FatSidebarItem) -> Bool {

        guard self.contains(item),
            item.isSelected
            else { return false }

        item.isSelected = false

        return true
    }

    /// First selected item (if any).
    ///
    /// **See** `selectedItems` for all selected items.
    public var selectedItem: FatSidebarItem? {
        return items.first(where: { $0.isSelected })
    }

    /// Collection of all selected items.
    ///
    /// **See** `selectedItem` for the first (or only) selected item.
    public var selectedItems: [FatSidebarItem] {
        return items.filter { $0.isSelected }
    }


    // MARK: - 
    // MARK: Layout

    fileprivate var laidOutItemBox: NSRect = NSRect.null
    public override var intrinsicContentSize: NSSize {
        return laidOutItemBox.size
    }

    public override var frame: NSRect {
        didSet {
            layoutItems()
        }
    }

    fileprivate func layoutItems() {

        let wholeFrame = self.frame
        let itemSize = NSSize(quadratic: wholeFrame.width)

        var allItemsFrame = NSRect.zero
        for (i, item) in items.enumerated() {

            let origin = NSPoint(
                x: 0,
                // On macOS, the coordinate system starts in the bottom-left corner
                y: wholeFrame.maxY - CGFloat(i + 1) * itemSize.height)
            let newItemFrame = NSRect(origin: origin, size: itemSize)

            item.frame = newItemFrame

            allItemsFrame = allItemsFrame.union(newItemFrame)
        }

        laidOutItemBox = allItemsFrame
    }

    // MARK: Drawing

    @IBInspectable var backgroundColor: NSColor?

    public override func draw(_ dirtyRect: NSRect) {

        let wholeFrame = self.frame

        super.draw(wholeFrame)

        drawBackground(wholeFrame)
        drawItems()
    }

    fileprivate func drawBackground(_ dirtyRect: NSRect) {

        guard let backgroundColor = backgroundColor else { return }

        backgroundColor.set()
        NSRectFill(dirtyRect)
    }

    fileprivate func drawItems() {

        for item in items {
            item.draw(item.frame)
        }
    }
}
