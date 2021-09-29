import RealmSwift
import Foundation

public final class WriteTransaction {

    private let _realm: RealmWrapper
    private var realm: Realm { _realm.realm }
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
        queue.async { [weak self] in
            autoreleasepool {
                do {
                    guard let this = self else {
                        throw Realm.Error(.fail)
                    }
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
                    try closure(object, this)
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
