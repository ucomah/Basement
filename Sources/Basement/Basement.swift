@_exported import Foundation
@_exported import RealmSwift

/// A Root class wrapper for Realm database.
/// Since Realm is thread contained, we need to make sure that it's always accessed from the same queue it was initialized.
/// Other words, each `Realm()` instance has to be constructed for any perticular queue you're accessing it at the moment.
/// That is what Basement does - it wraps each Realm instance and makes it thread safe.
/// Also, it gives a tool like `Basement.Configuration` which allows to easily manage Realm databases on disk.
open class Basement {

    /// Creates a new instance with a default configuration.
    public static func `default`() throws -> Basement { try Basement() }
    /// Thread safe instance of Realm
    private static let _realm: ThreadSpecificVariable<RealmWrapper> = .init()

    /// Configuration used by current instance.
    public let configuration: Configuration

    public init(config: Configuration = .default) throws {
        self.configuration = config
        let rlmConf = try Realm.Configuration(conf: config)
        if Basement._realm.currentValue == nil || Basement._realm.currentValue?.realm.configuration != rlmConf {
            Basement._realm.currentValue = try RealmWrapper(conf: rlmConf)
        }
    }

    /// Creates a new instance of the `Basement` by initializing with exiting configuration.
    public func newInstance() throws -> Basement {
        try Basement(config: configuration)
    }
    
    /// Main getter Realm instance.
    func realm() throws -> Realm {
        if let r = Self._realm.currentValue {
            return r.realm
        }
        let r = try RealmWrapper(conf: .init(conf: configuration))
        Basement._realm.currentValue = r
        if _isDebugAssertConfiguration() {
            let name = Thread.current.name ?? ""
            let part = !name.isEmpty ? name : String(describing: withUnsafePointer(to: Thread.current) { $0 })
            print("🗞 \(type(of: self)): new instance for queue \(part)")
        }
        return r.realm
    }
}

