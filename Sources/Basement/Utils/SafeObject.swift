import Foundation
import RealmSwift
import Realm

public protocol SafeObject: ThreadConfined { }

extension SafeObject {
    
    public func safeFreeze() -> Self {
        guard !isFrozen else { return self }
        return self.freeze()
    }
    
    public func safeThaw() -> Self? {
        guard isFrozen, !isInvalidated else { return nil }
        return self.thaw()
    }
}
