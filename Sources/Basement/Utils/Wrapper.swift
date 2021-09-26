import RealmSwift
import Realm

/// This wrapper is needed to be able to store Realm instance as ThreadSpecificVariable.
final class RealmWrapper {
    
    let realm: Realm

    init(conf: Realm.Configuration, queue: DispatchQueue? = nil) throws {
        realm = try Realm(configuration: conf, queue: queue)
    }

    init(realm: Realm) {
        self.realm = realm
    }
}

extension Object {

    public static func from<T: Object>(value: Any) -> T {
        let obj = T()
        RLMInitializeWithValue(obj, value, .partialPrivateShared())
        return obj
    }

    public static func from<T: Object>(dictionary: [String: Any?]) -> T {
        return from(value: dictionary)
    }
}
