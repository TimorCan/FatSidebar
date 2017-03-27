//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa
import FatSidebar

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var fatSidebar: FatSidebar!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        fatSidebar.removeFromSuperview()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        fatSidebar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = fatSidebar

        fatSidebar.theme = OmniFocusTheme()
        fatSidebar.appendItem(
            title: "Inbox",
            image: #imageLiteral(resourceName: "inbox.png"),
            callback: { _ in print("Inbox") })
        fatSidebar.appendItem(
            title: "Favorites",
            image: #imageLiteral(resourceName: "heart.png"),
            callback: { _ in print("Favs") })
        fatSidebar.appendItem(
            title: "Ideas",
            image: #imageLiteral(resourceName: "lightbulb.png"),
            callback: { _ in print("Ideas") })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
