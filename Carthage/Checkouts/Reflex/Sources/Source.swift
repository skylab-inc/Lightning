//
//  SignalProducer.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

public final class Source<V, E: Swift.Error>: SourceType, InternalSignalType, SpecialSignalGenerator {
    
    public typealias Value = V
    public typealias Error = E
    
    internal var observers = Bag<Observer<Value, Error>>()

    public var source: Source {
        return self
    }
    
    internal let startHandler: (Observer<Value, Error>) -> Disposable?
    
    var cancelDisposable: Disposable?
    
    private var started: Bool {
        if let disposable = cancelDisposable {
            return !disposable.disposed
        }
        return false
    }
    
    /// Initializes a Source that will invoke the given closure at the
    /// invocation of `start()`.
    ///
    /// The events that the closure puts into the given observer will become
    /// the events sent to this `Source`.
    ///
    /// In order to stop or dispose of the signal, invoke `stop()`. Calling this method
    /// will dispose of the disposable returned by the given closure.
    /// 
    /// Invoking `start()` will have no effect until the signal is stopped. After
    /// `stop()` is called this process may be repeated.
    public init(_ startHandler: @escaping (Observer<Value, Error>) -> Disposable?) {
        self.startHandler = startHandler
    }
    
    /// Creates a Signal from the producer, then attaches the given observer to
    /// the Signal as an observer.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the signal and immediately send an `Interrupted` event.
    @discardableResult
    public func start() {
        if !started {
            let observer = Observer(with: CircuitBreaker(holding: self))
            let handlerDisposable = startHandler(observer)
            
            // The cancel disposable should send interrupted and then dispose of the 
            // disposable produced by the startHandler.
            cancelDisposable = ActionDisposable {
                observer.sendInterrupted()
                handlerDisposable?.dispose()
            }
        }
    }
    
    public func stop() {
        cancelDisposable?.dispose()
    }

    deinit {
        self.stop()
    }

}

extension Source: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let obs = Array(self.observers.map { String(describing: $0) })
        return "Source[\(obs.joined(separator: ", "))]"
    }
    
}

public protocol SourceType: SignalType {
    
    /// The exposed raw signal that underlies the SourceType
    var source: Source<Value, Error> { get }
    
    /// Invokes the closure provided upon initialization, and passes in a newly
    /// created observer to which events can be sent.
    func start()
    
    /// Stops the `Source` by sending an interrupt to all of it's
    /// observers and then invoking the disposable returned by the closure
    /// that was provided upon initialization.
    func stop()
    
}

public extension SourceType {
    
    public var signal: Signal<Value, Error> {
        return Signal { observer in
            self.source.add(observer: observer)
        }
    }
    
    /// Invokes the closure provided upon initialization, and passes in a newly
    /// created observer to which events can be sent.
    func start() {
        source.start()
    }
    
    /// Stops the `Source` by sending an interrupt to all of it's
    /// observers and then invoking the disposable returned by the closure
    /// that was provided upon initialization.
    func stop() {
        source.stop()
    }

}

public extension SourceType {
    
    /// Adds an observer to the `Source` which observes any future events from the
    /// `Source`. If the `Signal` has already terminated, the observer will immediately
    /// receive an `Interrupted` event.
    ///
    /// Returns a Disposable which can be used to disconnect the observer. Disposing
    /// of the Disposable will have no effect on the Signal itself.
    @discardableResult
    public func add(observer: Observer<Value, Error>) -> Disposable? {
        let token = source.observers.insert(observer)
        return ActionDisposable { [weak source = source] in
            source?.observers.remove(using: token)
        }
    }
    
    /// Creates a `Source`, adds exactly one observer, and then immediately
    /// invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func start(with observer: Observer<Value, Error>) -> Disposable? {
        let disposable = source.add(observer: observer)
        source.start()
        return disposable
    }

    /// Creates a `Source`, adds exactly one observer, and then immediately
    /// invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func start(_ observerAction: @escaping Observer<Value, Error>.Action) -> Disposable? {
        return start(with: Observer(observerAction))
    }
    
    /// Creates a `Source`, adds exactly one observer for next, and then immediately
    /// invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func startWithNext(next: @escaping (Value) -> Void) -> Disposable? {
        return start(with: Observer(next: next))
    }
    
    /// Creates a `Source`, adds exactly one observer for completed events, and then
    /// immediately invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func startWithCompleted(completed: @escaping () -> Void) -> Disposable? {
        return start(with: Observer(completed: completed))
    }
    
    /// Creates a `Source`, adds exactly one observer for errors, and then
    /// immediately invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func startWithFailed(failed: @escaping (Error) -> Void) -> Disposable? {
        return start(with: Observer(failed: failed))
    }
    
    /// Creates a `Source`, adds exactly one observer for interrupts, and then
    /// immediately invokes start on the `Source`.
    ///
    /// Returns a Disposable which can be used to dispose of the added observer.
    @discardableResult
    public func startWithInterrupted(interrupted: @escaping () -> Void) -> Disposable? {
        return start(with: Observer(interrupted: interrupted))
    }

}

public extension SourceType {
    
    /// Creates a new `Source` which will apply a unary operator directly to events
    /// produced by the `startHandler`.
    ///
    /// The new `Source` is in no way related to the source `Source` except
    /// that they share a reference to the same `startHandler`.
    public func lift<U, F>(_ transform: @escaping (Signal<Value, Error>) -> Signal<U, F>) -> Source<U, F> {
        return Source { observer in
            let (pipeSignal, pipeObserver) = Signal<Value, Error>.pipe()
            transform(pipeSignal).add(observer: observer)
            return self.source.startHandler(pipeObserver)
        }
    }
    
    public func lift<U, F>(_ transform: @escaping (Signal<Value, Error>) -> (Signal<U, F>, Signal<U, F>))
        -> (Source<U, F>, Source<U, F>)
    {
        let (pipeSignal, pipeObserver) = Signal<Value, Error>.pipe()
        let (left, right) = transform(pipeSignal)
        let sourceLeft = Source<U, F> { observer in
            left.add(observer: observer)
            return self.source.startHandler(pipeObserver)
        }
        let sourceRight = Source<U, F> { observer in
            right.add(observer: observer)
            return self.source.startHandler(pipeObserver)
        }
        return (sourceLeft, sourceRight)
    }

    public var identity: Source<Value, Error> {
        return lift { $0.identity }
    }
    
    /// Maps each value in the signal to a new value.
    public func map<U>(_ transform: @escaping (Value) -> U) -> Source<U, Error> {
        return lift { $0.map(transform) }
    }
    
    /// Maps errors in the signal to a new error.
    public func mapError<F>(_ transform: @escaping (Error) -> F) -> Source<Value, F> {
        return lift { $0.mapError(transform) }
    }
    
    /// Preserves only the values of the signal that pass the given predicate.
    public func filter(_ predicate: @escaping (Value) -> Bool) -> Source<Value, Error> {
        return lift { $0.filter(predicate) }
    }
    
    /// Splits the signal into two signals. The first signal in the tuple matches the
    /// predicate, the second signal does not match the predicate
    public func partition(_ predicate: @escaping (Value) -> Bool)
        -> (Source<Value, Error>, Source<Value, Error>) {
        return lift { $0.partition(predicate) }
    }
    
    /// Aggregate values into a single combined value. Mirrors the Swift Collection
    public func reduce<T>(initial: T, _ combine: @escaping (T, Value) -> T) -> Source<T, Error> {
        return lift { $0.reduce(initial: initial, combine) }
    }
    
    public func flatMap<U>(_ transform: @escaping (Value) -> U?) -> Source<U, Error> {
        return lift { $0.flatMap(transform) }
    }

    public func flatMap<U>(_ transform: @escaping (Value) -> Source<U, Error>) -> Source<U, Error> {
        return lift { $0.map(transform).joined() }
    }


}

