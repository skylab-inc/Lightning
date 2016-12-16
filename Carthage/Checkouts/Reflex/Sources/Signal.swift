//
//  Signal.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

public final class Signal<Value, Error: Swift.Error>: SignalType, InternalSignalType, SpecialSignalGenerator {
    
    internal var observers = Bag<Observer<Value, Error>>()
    
    private var handlerDisposable: Disposable?

    var cancelDisposable: Disposable?

    public var signal: Signal<Value, Error> {
        return self
    }
    
    /// Initializes a Signal that will immediately invoke the given generator,
    /// then forward events sent to the given observer.
    ///
    /// The disposable returned from the closure will be automatically disposed
    /// if a terminating event is sent to the observer. The Signal itself will
    /// remain alive until the observer is released. This is because the observer
    /// captures a self reference.
    public init(_ startHandler: @escaping (Observer<Value, Error>) -> Disposable?) {
        
        let observer = Observer(with: CircuitBreaker(holding: self))
        let handlerDisposable = startHandler(observer)

        // The cancel disposable should send interrupted and then dispose of the
        // disposable produced by the startHandler.
        cancelDisposable = ActionDisposable {
            observer.sendInterrupted()
            handlerDisposable?.dispose()
        }
    }
    
    deinit {
        cancelDisposable?.dispose()
    }
    
    /// Creates a Signal that will be controlled by sending events to the returned
    /// observer.
    ///
    /// The Signal will remain alive until a terminating event is sent to the
    /// observer.
    public static func pipe() -> (Signal, Observer<Value, Error>) {
        var observer: Observer<Value, Error>!
        let signal = self.init { innerObserver in
            observer = innerObserver
            return nil
        }
        return (signal, observer)
    }
}

extension Signal: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let obs = Array(self.observers.map { String(describing: $0) })
        return "Signal[\(obs.joined(separator: ", "))]"
    }
    
}

public protocol SpecialSignalGenerator {
    
    /// The type of values being sent on the signal.
    associatedtype Value
    
    /// The type of error that can occur on the signal. If errors aren't possible
    /// then `NoError` can be used.
    associatedtype Error: Swift.Error
    
    init(_ generator: @escaping (Observer<Value, Error>) -> Disposable?)
    
}

public extension SpecialSignalGenerator {
    
    /// Creates a Signal that will immediately send one value
    /// then complete.
    public init(value: Value) {
        self.init { observer in
            observer.sendNext(value)
            observer.sendCompleted()
            return nil
        }
    }
    
    /// Creates a Signal that will immediately fail with the
    /// given error.
    public init(error: Error) {
        self.init { observer in
            observer.sendFailed(error)
            return nil
        }
    }
    
    /// Creates a Signal that will immediately send the values
    /// from the given sequence, then complete.
    public init<S: Sequence>(values: S) where S.Iterator.Element == Value {
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
    
    /// Creates a Signal that will immediately send the values
    /// from the given sequence, then complete.
    public init(values: Value...) {
        self.init(values: values)
    }
    
    /// A Signal that will immediately complete without sending
    /// any values.
    public static var empty: Self {
        return self.init { observer in
            observer.sendCompleted()
            return nil
        }
    }
    
    /// A Signal that never sends any events to its observers.
    public static var never: Self {
        return self.init { _ in return nil }
    }
    
}

/// An internal protocol for adding methods that require access to the observers
/// of the signal.
internal protocol InternalSignalType: SignalType {

    var observers: Bag<Observer<Value, Error>> { get }

}

public protocol SignalType {
    
    /// The type of values being sent on the signal.
    associatedtype Value
    
    /// The type of error that can occur on the signal. If errors aren't possible
    /// then `NoError` can be used.
    associatedtype Error: Swift.Error
    
    /// The exposed raw signal that underlies the `SignalType`.
    var signal: Signal<Value, Error> { get }

    var cancelDisposable: Disposable { get }

}

public extension SignalType {

    var cancelDisposable: Disposable {
        return signal.cancelDisposable
    }

}

public extension SignalType {
    
    /// Adds an observer to the `Signal` which observes any future events from the `Signal`.
    /// If the `Signal` has already terminated, the observer will immediately receive an
    /// `Interrupted` event.
    ///
    /// Returns a Disposable which can be used to disconnect the observer. Disposing
    /// of the Disposable will have no effect on the `Signal` itself.
    @discardableResult
    public func add(observer: Observer<Value, Error>) -> Disposable? {
        let token = signal.observers.insert(observer)
        return ActionDisposable {
            self.signal.observers.remove(using: token)
        }
        
    }

    /// Convenience override for add(observer:) to allow trailing-closure style
    /// invocations.
    @discardableResult
    public func on(action: @escaping Observer<Value, Error>.Action) -> Disposable? {
        return self.add(observer: Observer(action))
    }
    
    /// Observes the Signal by invoking the given callback when `next` events are
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callbacks. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    @discardableResult
    public func onNext(next: @escaping (Value) -> Void) -> Disposable? {
        return self.add(observer: Observer(next: next))
    }
    
    /// Observes the Signal by invoking the given callback when a `completed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    @discardableResult
    public func onCompleted(completed: @escaping () -> Void) -> Disposable? {
        return self.add(observer: Observer(completed: completed))
    }
    
    /// Observes the Signal by invoking the given callback when a `failed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    @discardableResult
    public func onFailed(error: @escaping (Error) -> Void) -> Disposable? {
        return self.add(observer: Observer(failed: error))
    }
    
    /// Observes the Signal by invoking the given callback when an `interrupted` event is
    /// received. If the Signal has already terminated, the callback will be invoked
    /// immediately.
    ///
    /// Returns a Disposable which can be used to stop the invocation of the
    /// callback. Disposing of the Disposable will have no effect on the Signal
    /// itself.
    @discardableResult
    public func onInterrupted(interrupted: @escaping () -> Void) -> Disposable? {
        return self.add(observer: Observer(interrupted: interrupted))
    }
    
}

public extension SignalType {
    
    public var identity: Signal<Value, Error> {
        return self.map { $0 }
    }
    
    /// Maps each value in the signal to a new value.
    public func map<U>(_ transform: @escaping (Value) -> U) -> Signal<U, Error> {
        return Signal { observer in
            return self.on { event -> Void in
                observer.send(event.map(transform))
            }
        }
    }
    
    /// Maps errors in the signal to a new error.
    public func mapError<F>(_ transform: @escaping (Error) -> F) -> Signal<Value, F> {
        return Signal { observer in
            return self.on { event -> Void in
                observer.send(event.mapError(transform))
            }
        }
    }
    
    /// Preserves only the values of the signal that pass the given predicate.
    public func filter(_ predicate: @escaping (Value) -> Bool) -> Signal<Value, Error> {
        return Signal { observer in
            return self.on { (event: Event<Value, Error>) -> Void in
                guard let value = event.value else {
                    observer.send(event)
                    return
                }
                
                if predicate(value) {
                    observer.sendNext(value)
                }
            }
        }
    }
    
    /// Splits the signal into two signals. The first signal in the tuple matches the
    /// predicate, the second signal does not match the predicate
    public func partition(_ predicate: @escaping (Value) -> Bool) -> (Signal<Value, Error>, Signal<Value, Error>) {
        let (left, leftObserver) = Signal<Value, Error>.pipe()
        let (right, rightObserver) = Signal<Value, Error>.pipe()
        self.on { (event: Event<Value, Error>) -> Void in
            guard let value = event.value else {
                leftObserver.send(event)
                rightObserver.send(event)
                return
            }
            
            if predicate(value) {
                leftObserver.sendNext(value)
            } else {
                rightObserver.sendNext(value)
            }
        }
        return (left, right)
    }
    
    /// Aggregate values into a single combined value. Mirrors the Swift Collection
    public func reduce<T>(initial: T, _ combine: @escaping (T, Value) -> T) -> Signal<T, Error> {
        return Signal { observer in
            var accumulator = initial
            return self.on { event in
                observer.send(event.map { value in
                    accumulator = combine(accumulator, value)
                    return accumulator
                })
            }
        }
    }
    
    public func flatMap<U>(_ transform: @escaping (Value) -> U?) -> Signal<U, Error> {
        return Signal { observer in
            return self.on { event -> Void in
                if let e = event.flatMap(transform) {
                    observer.send(e)
                }
            }
        }
    }


    public func flatMap<U>(_ transform: @escaping (Value) -> Source<U, Error>) -> Signal<U, Error> {
        return map(transform).joined()
    }
    
}

extension SignalType where Value: SourceType, Error == Value.Error {

    /// Listens to every `Source` produced from the current `Signal`
    /// Starts each `Source` and forwards on all values and errors onto
    /// the `Signal` which is returned. In this way it joins each of the
    /// `Source`s into a single `Signal`.
    ///
    /// The joined `Signal` completes when the current `Signal` and all of
    /// its produced `Source`s complete.
    ///
    /// Note: This means that each `Source` will be started as it is received.
    public func joined() -> Signal<Value.Value, Error> {
        // Start the number in flight at 1 for `self`

        return Signal { observer in

            var numberInFlight = 1
            var disposables = [Disposable]()
            func decrementInFlight() {
                numberInFlight -= 1
                if numberInFlight == 0 {
                    observer.sendCompleted()
                }
            }

            func incrementInFlight() {
                numberInFlight += 1
            }

            self.on { event in

                switch event {
                case .next(let source):
                    incrementInFlight()
                    source.on { event in
                        switch event {
                        case .completed, .interrupted:
                            decrementInFlight()

                        case .next, .failed:
                            observer.send(event)
                        }
                    }
                    disposables.append(source.cancelDisposable)
                    source.start()

                case .failed(let error):
                    observer.sendFailed(error)

                case .completed:
                    decrementInFlight()

                case .interrupted:
                    observer.sendInterrupted()
                }

            }

            return ActionDisposable {
                for disposable in disposables {
                    disposable.dispose()
                }
            }
            
        }
    }
}
