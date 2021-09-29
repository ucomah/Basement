import Foundation
import RealmSwift

public struct CollectionChanges<T: RealmCollectionValue>: CustomStringConvertible, CustomDebugStringConvertible {
    
    public let insertsions: [Int]
    public let modifications: [Int]
    public let deletions: [Int]
    public let isInitialUpdate: Bool
    
    public internal(set) var items: Results<T>?

    public var isEmpty: Bool {
        insertsions.isEmpty && modifications.isEmpty && deletions.isEmpty
    }

    public var description: String {
        """
        Changes<\(withUnsafePointer(to: self) { $0 })>
        insertions: \(insertsions)
        mofifications: \(modifications)
        deletions: \(deletions)
        isInitial" \(isInitialUpdate)
        """
    }

    public var debugDescription: String {
        description
    }
    
    internal init(insertions: [Int], modifications: [Int], deletions: [Int], initial: Bool) {
        self.insertsions = insertions
        self.modifications = modifications
        self.deletions = deletions
        self.isInitialUpdate = initial
    }
    
    public init<T: RealmCollection>(changeset: RealmCollectionChange<T>) throws {
        switch changeset {
        case .initial(let all):
            self = CollectionChanges(insertions: (0 ..< all.count).map { $0 }, modifications: [], deletions: [], initial: true)
        case .update(_, let deletions, let insertions, let modifications):
            self = CollectionChanges(insertions: insertions, modifications: modifications, deletions: deletions, initial: false)
        case .error(let error):
            throw error
        }
    }
}
