//
//  Observer.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation


/// A CiruitBreaker optionally holds a strong reference to either a
/// `Signal` or a `Source` until a terminating event is
/// received. At such time, it delivers the event and then 
/// removes its reference. In so doing, it "breaks the circuit"
/// between the signal, the handler, and the input observer.
/// This allows the downstream signal to be released.
class CircuitBreaker<Value, Error: Swift.Error>  {

    private var signal: Signal<Value, Error>? = nil
    private var source: Source<Value, Error>? = nil
    fileprivate var action: Observer<Value, Error>.Action! = nil
    
    /// Holds a strong reference to a `Signal` until a 
    /// terminating event is received.
    init(holding signal: Signal<Value, Error>?) {
        self.signal = signal
        self.action = { [weak self] event in
            self?.signal?.observers.forEach { observer in
                observer.send(event)
            }
            
            if event.isTerminating {
                // Do not have to dispose of cancel disposable
                // since it will be disposed when the signal is deallocated.
                self?.signal = nil
            }
        }
    }
    
    /// Holds a strong reference to a `Source` until a
    /// terminating event is received.
    init(holding source: Source<Value, Error>?) {
        self.source = source
        self.action = { [weak self] event in
            self?.source?.observers.forEach { observer in
                observer.send(event)
            }
            
            if event.isTerminating {
                // Do not have to dispose of cancel disposable
                // since it will be disposed when the signal is deallocated.
                self?.source = nil
            }
        }
    }
    
    fileprivate init(with action: @escaping (Event<Value, Error>) -> Void) {
        self.action = action
    }
    
}


public struct Observer<Value, Error: Swift.Error> {
    
    public typealias Action = (Event<Value, Error>) -> Void
    let breaker: CircuitBreaker<Value, Error>
    
    init(with breaker: CircuitBreaker<Value, Error>) {
        self.breaker = breaker
    }
    
    public init(_ action: @escaping Action) {
        self.breaker = CircuitBreaker(with: action)
    }
    
    /// Creates an Observer with an action which calls each of the provided 
    /// callbacks
    public init(
        failed: ((Error) -> Void)? = nil,
        completed: (() -> Void)? = nil,
        interrupted: (() -> Void)? = nil,
        next: ((Value) -> Void)? = nil)
    {
        self.init { event in
            switch event {
            case let .next(value):
                next?(value)
                
            case let .failed(error):
                failed?(error)
                
            case .completed:
                completed?()
                
            case .interrupted:
                interrupted?()
            }
        }
    }
    
    /// Puts any `Event` into the the given observer.
    public func send(_ event: Event<Value, Error>) {
        breaker.action(event)
    }
    
    /// Puts a `Next` event into the given observer.
    public func sendNext(_ value: Value) {
        send(.next(value))
    }
    
    /// Puts an `Failed` event into the given observer.
    public func sendFailed(_ error: Error) {
        send(.failed(error))
    }
    
    /// Puts a `Completed` event into the given observer.
    public func sendCompleted() {
        send(.completed)
    }
    
    /// Puts a `Interrupted` event into the given observer.
    public func sendInterrupted() {
        send(.interrupted)
    }
}
