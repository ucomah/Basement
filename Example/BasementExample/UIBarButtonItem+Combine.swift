import UIKit
import Combine

extension UIBarButtonItem {
    
    public struct ActionPublisher: Publisher {
        
        public typealias Output = Void
        public typealias Failure = Never
        
        fileprivate var button: UIBarButtonItem
        
        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
            
            let subscription = ActionSubscription<S>()
            subscription.target = subscriber
            
            subscriber.receive(subscription: subscription)
            
            button.target = subscription
            button.action = #selector(subscription.trigger)
        }
    }
}

fileprivate extension UIBarButtonItem {
    final class ActionSubscription<Target: Subscriber>: Subscription where Target.Input == Void {
        
        var target: Target?
        
        func request(_ demand: Subscribers.Demand) { }
        
        func cancel() {
            target = nil
        }
        
        @objc func trigger() {
            _ = target?.receive(())
        }
    }
}

extension UIBarButtonItem {
    public func actionPublisher() -> ActionPublisher {
        ActionPublisher(button: self)
    }
}

