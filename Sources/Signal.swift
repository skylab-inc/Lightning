//
//  Signal.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

public final class Signal<Value, Error: ErrorProtocol>: SignalType, InternalSignalType {
    public typealias Observer = Edge.Observer<Value, Error>
    
    internal var observers = Bag<Observer>()
    
    /// Initializes a Signal that will immediately invoke the given generator,
    /// then forward events sent to the given observer.
    ///
    /// The disposable returned from the closure will be automatically disposed
    /// if a terminating event is sent to the observer. The Signal itself will
    /// remain alive until the observer is released.
    public init(_ generator: (Observer) -> Disposable?) {
        
        let generatorDisposable = SerialDisposable()

        let inputObserver = Observer { event in
            if case .Interrupted = event {
                
                self.interrupt()
                
            } else {
                self.observers.forEach { (observer) in
                    observer.action(event)
                }
                
                if event.isTerminating {
                    generatorDisposable.dispose()
                }
            }
        }
        
        generatorDisposable.innerDisposable = generator(inputObserver)
    }
    
    /// Observes the Signal by sending any future events to the given observer. If
    /// the Signal has already terminated, the observer will immediately receive an
    /// `Interrupted` event.
    ///
    /// Returns a Disposable which can be used to disconnect the observer. Disposing
    /// of the Disposable will have no effect on the Signal itself.
    public func add(observer: Observer) -> Disposable? {
        let token = observers.insert(value: observer)
        return ActionDisposable { [weak self] in
            self?.observers.removeValueForToken(token: token)
        }
    
    }
}

public protocol SignalType {
    /// The type of values being sent on the signal.
    associatedtype Value
    /// The type of error that can occur on the signal. If errors aren't possible
    /// then `NoError` can be used.
    associatedtype Error: ErrorProtocol
    
    /// Observes the Signal by sending any future events to the given observer.
//    func add(observer: Signal<Value, Error>.Observer) -> Disposable?
    func add(observer: Observer<Value, Error>) -> Disposable?

    init(_ generator: (Signal<Value, Error>.Observer) -> Disposable?)
}

internal protocol InternalSignalType: SignalType {
    
    var observers: Bag<Observer<Value, Error>> { get }

}

extension InternalSignalType {
    
    /// Interrupts all observers and terminates the stream.
    func interrupt() {
        for observer in self.observers {
            observer.sendInterrupted()
        }
    }
    
}

extension SignalType {
    
    /// Creates a producer for a Signal that will immediately send one value
    /// then complete.
    public init(value: Value) {
        self.init { observer in
            observer.sendNext(value)
            observer.sendCompleted()
            return nil
        }
    }
    
    /// Creates a producer for a Signal that will immediately fail with the
    /// given error.
    public init(error: Error) {
        self.init { observer in
            observer.sendFailed(error)
            return nil
        }
    }
    
    /// Creates a producer for a Signal that will immediately send one value
    /// then complete, or immediately fail, depending on the given Result.
    public init(result: Result<Value, Error>) {
        switch result {
        case let .Success(value):
            self.init(value: value)
            
        case let .Failure(error):
            self.init(error: error)
        }
    }
    
    /// Creates a producer for a Signal that will immediately send the values
    /// from the given sequence, then complete.
    public init<S: Sequence where S.Iterator.Element == Value>(values: S) {
        self.init { observer in
            var disposed = false
            for value in values {
                observer.sendNext(value)
                
                if disposed {
                    break
                }
            }
            observer.sendCompleted()
            
            return ActionDisposable {
                disposed = true
            }
        }
    }
    
    /// Creates a producer for a Signal that will immediately send the values
    /// from the given sequence, then complete.
    public init(values: Value...) {
        self.init(values: values)
    }
    
    /// A producer for a Signal that will immediately complete without sending
    /// any values.
    public static var empty: Self {
        return self.init { observer in
            observer.sendCompleted()
            return nil
        }
    }
    
    /// A producer for a Signal that never sends any events to its observers.
    public static var never: Self {
        return self.init { _ in return nil }
    }
    
    /// Creates a Signal that will be controlled by sending events to the given
    /// observer.
    ///
    /// The Signal will remain alive until a terminating event is sent to the
    /// observer.
    public static func pipe() -> (Self, Signal<Value, Error>.Observer) {
        var observer: Signal<Value, Error>.Observer!
        let signal = self.init { innerObserver in
            observer = innerObserver
            return nil
        }
        return (signal, observer)
    }
    
    /// Creates a SignalProducer that will attempt the given operation once for
    /// each invocation of start().
    ///
    /// Upon success, the started signal will send the resulting value then
    /// complete. Upon failure, the started signal will fail with the error that
    /// occurred.
    public static func attempt(operation: () -> Result<Value, Error>) -> Self {
        return self.init { observer in
            operation().analysis(ifSuccess: { value in
                observer.sendNext(value)
                observer.sendCompleted()
                }, ifFailure: { error in
                    observer.sendFailed(error)
            })
            return nil
        }
    }
    
    /// Convenience override for observe(_:) to allow trailing-closure style
    /// invocations.
    public func on(action: Signal<Value, Error>.Observer.Action) -> Disposable? {
        return add(observer: Observer(action))
    }
    
    /// Observes the Signal by invoking the given callback when `next` events are
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callbacks. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    public func onNext(next: (Value) -> Void) -> Disposable? {
        return add(observer: Observer(next: next))
    }
    
    /// Observes the Signal by invoking the given callback when a `completed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    public func onCompleted(completed: () -> Void) -> Disposable? {
        return add(observer: Observer(completed: completed))
    }
    
    /// Observes the Signal by invoking the given callback when a `failed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    public func onFailed(error: (Error) -> Void) -> Disposable? {
        return add(observer: Observer(failed: error))
    }
    
    /// Observes the Signal by invoking the given callback when an `interrupted` event is
    /// received. If the Signal has already terminated, the callback will be invoked
    /// immediately.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    public func onInterrupted(interrupted: () -> Void) -> Disposable? {
        return add(observer: Observer(interrupted: interrupted))
    }
    
    /// Maps each value in the signal to a new value.
    @warn_unused_result(message: "Did you forget to call `observe` on the signal?")
    public func map<U>(transform: (Value) -> U) -> Signal<U, Error> {
        return Signal { observer in
            return self.on { event -> Void in
                observer.action(event.map(transform))
            }
        }
    }
    
    /// Maps errors in the signal to a new error.
    @warn_unused_result(message: "Did you forget to call `observe` on the signal?")
    public func mapError<F>(transform: (Error) -> F) -> Signal<Value, F> {
        return Signal { observer in
            return self.on { event -> Void in
                observer.action(event.mapError(transform))
            }
        }
    }
    
    /// Preserves only the values of the signal that pass the given predicate.
    @warn_unused_result(message: "Did you forget to call `observe` on the signal?")
    public func filter(predicate: (Value) -> Bool) -> Signal<Value, Error> {
        return Signal { observer in
            return self.on { (event: Event<Value, Error>) -> Void in
                guard let value = event.value else {
                    observer.action(event)
                    return
                }
                
                if predicate(value) {
                    observer.sendNext(value)
                }
            }
        }
    }
}