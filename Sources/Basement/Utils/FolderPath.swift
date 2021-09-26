public protocol LocalPathRepresentable {
    var searchPath: FileManager.SearchPathDirectory { get }
    var subPath: String? { get }
}

public extension LocalPathRepresentable {
    func url() throws -> URL {
        let list = NSSearchPathForDirectoriesInDomains(searchPath, .userDomainMask, true)
        guard let dir = list.first else {
            throw CocoaError.error(CocoaError.Code(rawValue: NSFileReadUnknownError))
        }
        if let p = subPath {
            return URL(fileURLWithPath: dir).appendingPathComponent(p)
        }
        return URL(fileURLWithPath: dir)
    }
}

@frozen
public struct FolderPath: LocalPathRepresentable, Hashable {
    public let searchPath: FileManager.SearchPathDirectory
    public let subPath: String?

    public init(_ directory: FileManager.SearchPathDirectory, subPath: String? = nil) {
        self.searchPath = directory
        self.subPath = subPath
    }

    public static var `default`: FolderPath { .init(.documentDirectory, subPath: "Realm") }
}

public extension FileManager {

    func folderItems(at url: URL, options: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: options)
    }

    func cleanFolder(at url: URL) throws {
        try folderItems(at: url, options: []).forEach { try removeItem(at: $0) }
    }
}
