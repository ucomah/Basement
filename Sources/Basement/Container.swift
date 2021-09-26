import RealmSwift
import Foundation

/// A Root class wrapper for Realm database.
/// Since Realm is thread contained, we need to make sure that it's always accessed from the same queue it was initialized.
/// Other words, each `Realm()` instance has to be constructed for any perticular queue you're accessing it at the moment.
/// That is what Container does - it wraps each Realm instance and makes it thread safe.
/// Also, it gives a tool like `Container.Configuration` which allows to easily manage Realm databases on disk.
open class Container {

    /// Creates a new instance with a default configuration.
    public static func `default`() throws -> Container { try Container(settings: SettingsList.default) }
    /// Thread safe instance of Realm
    private static let _realm: ThreadSpecificVariable<RealmWrapper> = .init()
    
    private let configuration: Realm.Configuration
    private let queue: DispatchQueue?
    
    public convenience init(settings: RealmCofigurationAffecting = SettingsList.default, queue: DispatchQueue? = nil) throws {
        var conf = Realm.Configuration()
        try settings.affect(&conf)
        try self.init(configuration: conf, queue: queue)
    }
    
    init(configuration: Realm.Configuration, queue: DispatchQueue? = nil) throws {
        self.configuration = configuration
        self.queue = queue
        if Container._realm.currentValue == nil || Container._realm.currentValue?.realm.configuration != configuration {
            Container._realm.currentValue = try RealmWrapper(conf: configuration, queue: queue)
        }
    }

    /// Creates a new instance of the `Container` by initializing with exiting configuration.
    public func newInstance(queue: DispatchQueue? = nil) throws -> Container {
        try Container(configuration: configuration, queue: queue)
    }
    
    /// Main getter Realm instance.
    func realm() throws -> Realm {
        if let r = Self._realm.currentValue {
            return r.realm
        }
        let r = try RealmWrapper(conf: configuration, queue: self.queue)
        Container._realm.currentValue = r
        if _isDebugAssertConfiguration() {
            let name = Thread.current.name ?? ""
            let part = !name.isEmpty ? name : String(describing: withUnsafePointer(to: Thread.current) { $0 })
            print("🗞 \(type(of: self)): new instance for queue \(part)")
        }
        return r.realm
    }
}
