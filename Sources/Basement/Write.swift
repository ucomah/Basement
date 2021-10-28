import RealmSwift
import Foundation

public final class WriteTransaction {

    private let _realm: RealmWrapper
    internal var realm: Realm { _realm.realm }
    
    public var container: Container? {
        try? Container(configuration: realm.configuration)
    }
    
    internal init(realm: RealmWrapper) {
        self._realm = realm
    }

    public func add<T: Object>(_ object: T, update: Realm.UpdatePolicy = .modified) {
        realm.add(object, update: update)
    }

    public func add<T: Sequence>(_ items: T, update: Realm.UpdatePolicy = .modified) where T.Iterator.Element: Object {
        realm.add(items, update: update)
    }

    public func delete<T: Object>(_ object: T) {
        realm.delete(object)
    }

    public func delete<T: Sequence>(in sequence: T) where T.Iterator.Element: Object {
        realm.delete(sequence)
    }
    
    public func async<T: ThreadConfined>(_ passedObject: T,
                                         queue: DispatchQueue? = nil,
                                         errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in return },
                                         closure: @escaping ((T, WriteTransaction) throws -> Void)) {
        let objectReference: ThreadSafeReference<T>? = passedObject.realm != nil ? ThreadSafeReference(to: passedObject) : nil
        let configuration = self.realm.configuration
        let queue = queue ?? backgroundQueue
        queue.async {
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: configuration)
                    let object: T
                    if let ref = objectReference {
                        if let obj = realm.resolve(ref) {
                            // Resolve within the transaction to ensure you get the latest changes from other threads
                            object = obj
                        } else {
                            throw Realm.Error(.fail)
                        }
                    } else {
                        object = passedObject
                    }
                    try realm.write {
                        try closure(object, WriteTransaction(realm: .init(realm: realm)))
                    }
                } catch {
                    errorHandler(error)
                }
            }
        }
    }
    
    public func async<T: ThreadConfined>(_ passedArray: [T],
                                   queue: DispatchQueue? = nil,
                                   errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in return },
                                   closure: @escaping (([T], WriteTransaction) throws -> Void)) {
        
        let arrayReference: [ThreadSafeReference<T>]?
        if let _ = passedArray.first(where: { $0.realm != nil }) {
            arrayReference = passedArray.map { ThreadSafeReference(to: $0) }
        } else {
            arrayReference = nil
        }
        let configuration = self.realm.configuration
        let queue = queue ?? backgroundQueue
        queue.async {
            autoreleasepool {
                do {
                    let realm = try Realm(configuration: configuration)
                    let arr: [T]
                    if let ref = arrayReference {
                        // Resolve within the transaction to ensure you get the latest changes from other threads
                        arr = ref.compactMap { realm.resolve($0) }
                    } else {
                        arr = passedArray
                    }
                    try realm.write {
                        try closure(arr, WriteTransaction(realm: .init(realm: realm)))
                    }
                } catch {
                    errorHandler(error)
                }
            }
        }
    }
}

var backgroundQueue: DispatchQueue {
    .global(qos: .background)
}
