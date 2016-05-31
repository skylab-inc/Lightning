//
//  SignalProducer.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

public final class ColdSignal<Value, Error: ErrorProtocol>: ColdSignalType, InternalSignalType {
    public typealias ProducedSignal = Signal<Value, Error>
    public typealias Observer = Edge.Observer<Value, Error>
    
    internal var observers = Bag<Observer>()
    
    private let startHandler: (ProducedSignal.Observer) -> Disposable?
    
    private var cancelDisposable: Disposable?
    
    private var started = false
    
    /// Initializes a SignalProducer that will invoke the given closure once
    /// for each invocation of start().
    ///
    /// The events that the closure puts into the given observer will become
    /// the events sent by the started Signal to its observers.
    ///
    /// If the Disposable returned from start() is disposed or a terminating
    /// event is sent to the observer, the given CompositeDisposable will be
    /// disposed, at which point work should be interrupted and any temporary
    /// resources cleaned up.
    public init(_ generator: (ProducedSignal.Observer) -> Disposable?) {
        self.startHandler = generator
    }
    
    /// Creates a Signal from the producer, then attaches the given observer to
    /// the Signal as an observer.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the signal and immediately send an `Interrupted` event.
    public func start() {
        let observer = Observer { event in
            if case .Interrupted = event {
                
                self.interrupt()
                
            } else {
                self.observers.forEach { (observer) in
                    observer.action(event)
                }
                
                if event.isTerminating {
                    self.stop()
                }
            }
        }
        
        if !started {
            started = true
            cancelDisposable = startHandler(observer)
        }
    }
    

    
    public func stop() {
        cancelDisposable?.dispose()
        //TODO: probably send interrupt
        started = false
    }
    
    /// Observes the SignalProducer by sending any future events to the given observer. If
    /// the Signal has already terminated, the observer will immediately receive an
    /// `Interrupted` event.
    ///
    /// Returns a Disposable which can be used to disconnect the observer. Disposing
    /// of the Disposable will have no effect on the Signal itself.
    public func add(observer: Observer) -> Disposable? {
        let token = self.observers.insert(value: observer)
        return ActionDisposable {
            self.observers.removeValueForToken(token: token)
        }
    }
    
}

public protocol ColdSignalType: SignalType {
    
    func start()
    
    func stop()
    
}

extension ColdSignalType {
    
    public func start(with observer: Observer<Value, Error>) -> Disposable? {
        let disposable = add(observer: observer)
        start()
        return disposable
    }

    /// Convenience override for start(_:) to allow trailing-closure style
    /// invocations.
    public func start(_ observerAction: Signal<Value, Error>.Observer.Action) -> Disposable? {
        return start(with: Observer(observerAction))
    }
    
    /// Creates a Signal from the producer, then adds exactly one observer to
    /// the Signal, which will invoke the given callback when `next` events are
    /// received.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the Signal, and prevent any future callbacks from being invoked.
    public func startWithNext(next: (Value) -> Void) -> Disposable? {
        return start(with: Observer(next: next))
    }
    
    /// Creates a Signal from the producer, then adds exactly one observer to
    /// the Signal, which will invoke the given callback when a `completed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the Signal.
    public func startWithCompleted(completed: () -> Void) -> Disposable? {
        return start(with: Observer(completed: completed))
    }
    
    /// Creates a Signal from the producer, then adds exactly one observer to
    /// the Signal, which will invoke the given callback when a `failed` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the Signal.
    public func startWithFailed(failed: (Error) -> Void) -> Disposable? {
        return start(with: Observer(failed: failed))
    }
    
    /// Creates a Signal from the producer, then adds exactly one observer to
    /// the Signal, which will invoke the given callback when an `interrupted` event is
    /// received.
    ///
    /// Returns a Disposable which can be used to interrupt the work associated
    /// with the Signal.
    public func startWithInterrupted(interrupted: () -> Void) -> Disposable? {
        return start(with: Observer(interrupted: interrupted))
    }

}