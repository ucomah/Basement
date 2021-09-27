import RealmSwift
import Foundation

open class BaseObject: Object {

    open func safeFreeze() -> Self {
        guard !isFrozen else { return self }
        return super.freeze()
    }
    
    open func safeThaw() -> Self? {
        guard isFrozen, !isInvalidated else { return nil }
        return super.thaw()
    }
}
