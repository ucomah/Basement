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
}
