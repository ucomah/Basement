import Foundation
import Realm
import RealmSwift

public protocol DetachableObject: AnyObject {
    func detached() -> Self
}

extension Object: DetachableObject {

    public func detached() -> Self {
        let detached = type(of: self).init()
        for property in objectSchema.properties {
            guard let value = value(forKey: property.name) else { continue }
            if property.isArray == true {
                // Realm List property support
                let detachable = value as? DetachableObject
                detached.setValue(detachable?.detached(), forKey: property.name)
            } else if property.type == .object {
                // Realm Object property support
                let detachable = value as? DetachableObject
                detached.setValue(detachable?.detached(), forKey: property.name)
            } else {
                detached.setValue(value, forKey: property.name)
            }
        }
        return detached
    }
}

extension List: DetachableObject {
    public func detached() -> List<Element> {
        let result = List<Element>()
        forEach {
            if let detachable = $0 as? DetachableObject {
                assert(detachable.detached() as? Element != nil)
                guard let detached = detachable.detached() as? Element else { return }
                result.append(detached)
            } else {
                result.append($0) // Primitives are being passed by value - don't need to recreate
            }
        }
        return result
    }
}

public extension Sequence where Element: Object {
    func detached() -> [Element] {
        self.map { $0.detached() }
    }
}

public extension RealmCollection where Element: Object {
    func detached() -> [Element] {
        self.map { $0.detached() }
    }
}
