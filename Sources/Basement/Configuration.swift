extension Basement {
    
    /// Realm.Configuration wrapper.
    public struct Configuration {
        
        /// - NOTE: This configutation is aimed to be changed globally when it is needed
        /// e.g. when app starts or etc.
        public static var `default`: Basement.Configuration = .init()
        
        public var directory: FolderPath
        public var protection: FileProtectionType
        public var deleteOnMigration: Bool
        public init(directory: FolderPath = .default,
                    protection: FileProtectionType = .completeUnlessOpen,
                    deleteOnMigration: Bool = true) {
            self.directory = directory
            self.protection = protection
            self.deleteOnMigration = deleteOnMigration
        }
    }
}


// MARK: - Custom Realm Confirguration

extension Realm.Configuration {

    static func custom(at folder: URL, protection: FileProtectionType, deleteOnMigration: Bool = true) throws -> Realm.Configuration {
        // Prepare a folder
        let dirAttrs: [FileAttributeKey: Any] = [FileAttributeKey.protectionKey: protection]
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: dirAttrs)
        // Make configuration
        var config = Realm.Configuration()
        guard let fileURL = config.fileURL?.lastPathComponent else {
            throw Realm.Error(.fileNotFound)
        }
        var url = folder
        url.appendPathComponent(fileURL)
        config.fileURL = url
        // Initialize
        config.deleteRealmIfMigrationNeeded = deleteOnMigration
        return config
    }

    static func custom(at directory: FolderPath = .default,
                       protection: FileProtectionType = .completeUnlessOpen,
                       deleteOnMigration: Bool = true) throws -> Realm.Configuration {
        let url = try directory.url()
        return try custom(at: url, protection: protection, deleteOnMigration: deleteOnMigration)
    }
    
    init(conf: Basement.Configuration) throws {
        self = try Realm.Configuration.custom(
            at: conf.directory,
            protection: conf.protection,
            deleteOnMigration: conf.deleteOnMigration
        )
    }
}
