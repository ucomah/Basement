import Foundation
import RealmSwift

// MARK: - Realm Public Extension

public extension Realm {

    /// Sent when whole Realm database files were removed
    static let cleanNotification = NSNotification.Name("com.app.realm.cleanup.notification")

    /// Cleans all Realm files in it's folder
    static func flushDatabase(with config: Realm.Configuration) throws {
        guard var folder = config.fileURL else {
            throw Realm.Error(.fileNotFound)
        }
        folder.deleteLastPathComponent()
        let url = URL(fileURLWithPath: folder.path, isDirectory: true, relativeTo: nil)
        // Delete Realm files
        try FileManager.default.cleanFolder(at: url)
        // Check results
        let isEmpty = try FileManager.default.folderItems(at: url).isEmpty
        guard isEmpty else {
            throw Realm.Error(.fail)
        }
        try FileManager.default.removeItem(at: url)
        NotificationCenter.default.post(name: Realm.cleanNotification, object: nil)
    }
}
