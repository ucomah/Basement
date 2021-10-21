import Foundation
import RealmSwift

extension Realm.Configuration {
    
    /// Realm can compact it's file on disk when launching.
    /// This condition is value for the rule on when compacting should be initiated.
    /// Example: Default setting is having delta 0.5 and sizeLimit 100,
    /// which means compacting if the file is over 100MB in size and less than 50% 'used'.
    public enum CompactRule: Hashable {
        case sizeLimit(Int)
        case freeSpaceDelta(Double)
    }
    
    public struct Folder: RealmCofigurationAffecting {
        let folder: FolderPath
        let fileaName: String?
        let protection: FileProtectionType
        public init(folder: FolderPath, fileName: String? = nil, protection: FileProtectionType = .completeUnlessOpen) {
            self.folder = folder
            self.fileaName = fileName
            self.protection = protection
        }
        func affect(_ configuration: inout Realm.Configuration) throws {
            // Detect file name
            guard let name = self.fileaName ?? configuration.fileURL?.lastPathComponent else {
                throw Realm.Error(.fileNotFound)
            }
            // Create folder
            var url = try folder.url()
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
            url.appendPathComponent(name)
            configuration.fileURL = url
            // Set protection level
            guard let path = configuration.fileURL?.relativePath else {
                return
            }
            var attibutes = (try? FileManager.default.attributesOfItem(atPath: path)) ?? .init()
            attibutes[.protectionKey] = protection
            try FileManager.default.setAttributes(attibutes, ofItemAtPath: path)
        }
    }
    
    public struct DeleteOnMigration: RealmCofigurationAffecting {
        let value: Bool
        public init(value: Bool = true) {
            self.value = value
        }
        func affect(_ configuration: inout Realm.Configuration) throws {
            configuration.deleteRealmIfMigrationNeeded = value
        }
    }
    
    public struct Migration: RealmCofigurationAffecting {
        let value: MigrationBlock
        public init(value: @escaping MigrationBlock) {
            self.value = value
        }
        func affect(_ configuration: inout Realm.Configuration) throws {
            configuration.migrationBlock = value
        }
    }
    
    public struct InMemoryIdentifier: RealmCofigurationAffecting {
        let value: String?
        public init(value: String?) {
            self.value = value
        }
        func affect(_ configuration: inout Realm.Configuration) throws {
            configuration.inMemoryIdentifier = value
        }
    }
    
    public struct CompactOnLaunch: RealmCofigurationAffecting {
        let value: Set<CompactRule>
        public init(value: Set<CompactRule> = .default) {
            self.value = value
        }
        func affect(_ configuration: inout Realm.Configuration) throws {
            configuration.shouldCompactOnLaunch = { (totalBytes, usedBytes) -> Bool in
                // totalBytes refers to the size of the file on disk in bytes (data + free space)
                // usedBytes refers to the number of bytes used by data in the file
                let result = value.map { (rule) -> Bool in
                    switch rule {
                    case .sizeLimit(let limit):
                        return totalBytes > limit
                    case .freeSpaceDelta(let delta):
                        return (Double(usedBytes) / Double(totalBytes)) < delta
                    }
                }
                return !result.contains(false)
            }
        }
    }
}

public extension Set where Element == Container.Configuration.CompactRule {
    /// Default configuration set for ``Container.Settings``
    static var `default`: Set<Container.Configuration.CompactRule> = [.sizeLimit(100), .freeSpaceDelta(0.5)]
}

/// Protocol to determine a wrapper for `Realm.Configuration` items.
/// Each conformer, can affect Realm's configuration so the set of conformers can
/// build a new settings list.
protocol RealmCofigurationAffecting {
    func affect(_ configuration: inout Realm.Configuration) throws
}

extension Container.Configuration {

    @resultBuilder
    struct SettingsBuilder {

        static func buildBlock(_ components: RealmCofigurationAffecting...) throws -> Container.Configuration {
            var config = Realm.Configuration()
            try components.forEach { try $0.affect(&config) }
            return config
        }
        
        static func buildEither(first component: RealmCofigurationAffecting) -> RealmCofigurationAffecting {
            return component
        }
        
        static func buildEither(second component: RealmCofigurationAffecting) -> RealmCofigurationAffecting {
            return component
        }
    }

    public static func make(@SettingsBuilder content: () -> Container.Configuration) -> Container.Configuration {
        return content()
    }
}
