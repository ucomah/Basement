import RealmSwift
import Foundation

extension Container {

    /// Write transation in current thread (queue)
    public func write<T: ThreadConfined>(_ obj: T, block: (T, WriteTransaction) throws -> Void) throws {
        let wrapper = try self.wrapper()
        let transaction = WriteTransaction(realm: wrapper)
        try wrapper.realm.write { try block(obj, transaction) }
    }
 
    /// Performs write transaction into the new instance.
    public func instanceWrite<T: ThreadConfined>(_ obj: T, block: (T, WriteTransaction) -> Void) throws {
        try newInstance().write(obj, block: block)
    }
    
    public func writeAsync<T: ThreadConfined>(_ obj: T,
                                              queue: DispatchQueue? = nil,
                                              block: @escaping (T, WriteTransaction) throws -> Void,
                                              errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in return }) {
        do {
            let wrapper = try self.wrapper()
            let transaction = WriteTransaction(realm: wrapper)
            transaction.async(obj, queue: queue, errorHandler: errorHandler, closure: block)
        } catch {
            errorHandler(error)
        }
    }
}

#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Container {
    
    public func publishWrite<T: ThreadConfined>(_ obj: T,
                                              on queue: DispatchQueue?,
                                              block: @escaping ((T, WriteTransaction) throws -> Void)) -> AnyPublisher<T, Error> {
        let future = Future<T, Error> { [weak self] seal in
            guard let this = self else {
                seal(.failure(Realm.Error.callFailed))
                return
            }
            this.writeAsync(obj, queue: queue) { obj, tr in
                try block(obj, tr)
                seal(.success(obj))
            } errorHandler: { error in
                seal(.failure(error))
            }
        }
        return AnyPublisher(future)
    }
}

#endif // canImport(Combine)

