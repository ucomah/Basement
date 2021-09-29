import Foundation
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
