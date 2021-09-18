import Foundation

/// A `ThreadSpecificVariable` is a variable that can be read and set like a normal variable except that it holds
/// different variables per thread.
///
/// `ThreadSpecificVariable` is thread-safe so it can be used with multiple threads at the same time but the value
/// returned by `currentValue` is defined per thread.
///
/// - note: `ThreadSpecificVariable` has reference semantics.
///
/// Borrowed from SwiftNIO
///
public struct ThreadSpecificVariable<T: AnyObject> {
    
    private let key: pthread_key_t

    /// Initialize a new `ThreadSpecificVariable` without a current value (`currentValue == nil`).
    public init() {
        var key = pthread_key_t()
        let pthreadErr = pthread_key_create(&key) { ptr in
            Unmanaged<AnyObject>.fromOpaque(
                (ptr as UnsafeMutableRawPointer?)! // swiftlint:disable:this force_cast
            ).release()
        }
        precondition(pthreadErr == 0, "pthread_key_create failed, error \(pthreadErr)")
        self.key = key
    }

    /// Initialize a new `ThreadSpecificVariable` with `value` for the calling thread. After calling this, the calling
    /// thread will see `currentValue == value` but on all other threads `currentValue` will be `nil` until changed.
    ///
    /// - parameters:
    ///   - value: The value to set for the calling thread.
    public init(value: T) {
        self.init()
        self.currentValue = value
    }

    /// The value for the current thread.
    public var currentValue: T? {
        /// Get the current value for the calling thread.
        get {
            guard let raw = pthread_getspecific(self.key) else {
                return nil
            }
            return Unmanaged<T>.fromOpaque(raw).takeUnretainedValue()
        }

        /// Set the current value for the calling threads. The `currentValue` for all other threads remains unchanged.
        nonmutating set {
            if let raw = pthread_getspecific(self.key) {
                Unmanaged<T>.fromOpaque(raw).release()
            }
            let pthreadErr = pthread_setspecific(self.key, newValue.map { v -> UnsafeMutableRawPointer in
                Unmanaged.passRetained(v).toOpaque()
            })
            precondition(pthreadErr == 0, "pthread_setspecific failed, error \(pthreadErr)")
        }
    }
}
