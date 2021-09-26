import SwiftUI
extension Container {
    /// A list of predefined settings that `Basement` reslies on.
    /// - NOTE: This is not required to stick only to this list since `SettingsList`
    /// can be easily extended with any `RealmCofigurationAffecting` item.
    public enum Setting: Hashable {
        case directory(FolderPath)
        case protection(FileProtectionType)
        case deleteOnMigration
        case compactRules(Set<CompactRule>)
    }
}

extension Container.Setting {
    /// Realm can compact it's file on disk when launching.
    /// This condition is value for the rule on when compacting should be initiated.
    /// Example: Default setting is having delta 0.5 and sizeLimit 100,
    /// which means compacting if the file is over 100MB in size and less than 50% 'used'.
    public enum CompactRule: Hashable {
        case sizeLimit(Int)
        case freeSpaceDelta(Double)
    }
}

public extension Container.SettingsList {
    /// - NOTE: This configutation is aimed to be changed globally when it is needed
    /// e.g. when app starts or etc.
    @Container.SettingsBuilder
    static var `default`: RealmCofigurationAffecting {
        /* Container.Setting.deleteOnMigration */
        Container.Setting.directory(.default)
        Container.Setting.protection(.completeUnlessOpen)
        Container.Setting.compactRules(.default)
    }
}

public extension Set where Element == Container.Setting.CompactRule {
    /// Default configuration set for ``Container.Settings``
    static var `default`: Set<Container.Setting.CompactRule> = [.sizeLimit(100), .freeSpaceDelta(0.5)]
}

/// Protocol to determine a wrapper for `Realm.Configuration` items.
/// Each conformer, can affect Realm's configuration so the set of conformers can
/// build a new settings list.
public protocol RealmCofigurationAffecting {
    func affect(_ configuration: inout Realm.Configuration) throws
}

extension Container.Setting: RealmCofigurationAffecting {
    public func affect(_ configuration: inout Realm.Configuration) throws {
        switch self {
        case .compactRules(let rules):
            configuration.shouldCompactOnLaunch = { (totalBytes, usedBytes) -> Bool in
                // totalBytes refers to the size of the file on disk in bytes (data + free space)
                // usedBytes refers to the number of bytes used by data in the file
                let result = rules.map { (rule) -> Bool in
                    switch rule {
                    case .sizeLimit(let limit):
                        return totalBytes > limit
                    case .freeSpaceDelta(let delta):
                        return (Double(usedBytes) / Double(totalBytes)) < delta
                    }
                }
                return !result.contains(false)
            }
        case .deleteOnMigration:
            configuration.deleteRealmIfMigrationNeeded = true
        case .directory(let folder):
            guard let fileURL = configuration.fileURL?.lastPathComponent else {
                throw Realm.Error(.fileNotFound)
            }
            var url = try folder.url()
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
            url.appendPathComponent(fileURL)
            configuration.fileURL = url
        case .protection(let protection):
            guard let path = configuration.fileURL?.relativePath else {
                return
            }
            var attibutes = (try? FileManager.default.attributesOfItem(atPath: path)) ?? .init()
            attibutes[.protectionKey] = protection
            try FileManager.default.setAttributes(attibutes, ofItemAtPath: path)
        }
    }
}

extension Container {
    public typealias SettingsList = Array<RealmCofigurationAffecting>
}

extension Container.SettingsList: RealmCofigurationAffecting {
    public func affect(_ configuration: inout Realm.Configuration) throws {
        try forEach { try $0.affect(&configuration) }
    }
}

extension Container {

    @resultBuilder
    struct SettingsBuilder {

        static func buildBlock(_ components: RealmCofigurationAffecting...) -> RealmCofigurationAffecting {
            return components.map { $0 }
        }
        
        static func buildEither(first component: RealmCofigurationAffecting) -> RealmCofigurationAffecting {
            return component
        }
        
        static func buildEither(second component: RealmCofigurationAffecting) -> RealmCofigurationAffecting {
            return component
        }
    }

    public static func settings(@SettingsBuilder content: () -> RealmCofigurationAffecting) -> RealmCofigurationAffecting {
        return content()
    }
}
