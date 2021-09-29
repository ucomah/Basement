import Foundation
import RealmSwift
#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Container {
    
    struct RealmPublisher<Output, Failure: Swift.Error>: Publisher {
        
        public typealias Output = Output
        public typealias Failure = Failure
        
        private let block: (AnySubscriber<Output, Failure>) -> NotificationToken
        
        init(_ block: @escaping (AnySubscriber<Output, Failure>) -> NotificationToken) {
            self.block = block
        }
        
        func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
            subscriber.receive(subscription: RealmSubscription<Output, Failure>(subscriber: subscriber, block: block))
        }
    }
        
    fileprivate final class RealmSubscription<Output, Failure: Error>: Subscription {
        
        private var subscriber: AnySubscriber<Output, Failure>?
        private var token: NotificationToken?
        private var block: (AnySubscriber<Output, Failure>) -> NotificationToken
        
        init<S>(subscriber: S, block: @escaping (AnySubscriber<Output, Failure>) -> NotificationToken)
            where S: Subscriber, Failure == S.Failure, Output == S.Input {
                self.subscriber = AnySubscriber(subscriber)
                self.block = block
        }
        
        func request(_ demand: Subscribers.Demand) {
            guard let subscriber = subscriber, token == nil else { return }
            token = block(subscriber)
        }
        
        func cancel() {
            token?.invalidate()
            subscriber = nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, *)
extension Container {
    
    public func publishWrite<T: ThreadConfined>(_ obj: T,
                                              on queue: DispatchQueue?,
                                              block: @escaping ((T, WriteTransaction) throws -> Void)) -> AnyPublisher<T, Error> {
        Future<T, Error> { [weak self] seal in
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
        }.eraseToAnyPublisher()
    }
}

@available(OSX 10.15, iOS 13.0,  *)
extension RealmCollection where Self: RealmSubscribable {
    
    public func changesPublisher<T: RealmCollectionValue>(_ queue: DispatchQueue? = nil) -> AnyPublisher<CollectionChanges<T>, Error> {
        let publisher = Container.RealmPublisher<CollectionChanges<T>, Error>() { subscriber in
            self.observe(on: queue) { changeset in
                do {
                    let value = try CollectionChanges<T>.init(changeset: changeset)
                    _ = subscriber.receive(value)
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
        return publisher.eraseToAnyPublisher()
    }
}

#endif // canImport(Combine)
