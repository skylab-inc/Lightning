//
//  Observer.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

/// An Observer is a simple wrapper around a function which can receive Events
/// (typically from a Signal).
public struct Observer<Value, Error: ErrorProtocol> {
    public typealias Action = (Event<Value, Error>) -> Void
    
    public let action: Action
    
    public init(_ action: Action) {
        self.action = action
    }
    
    public init(failed: ((Error) -> Void)? = nil, completed: (() -> Void)? = nil, interrupted: (() -> Void)? = nil, next: ((Value) -> Void)? = nil) {
        self.init { event in
            switch event {
            case let .Next(value):
                next?(value)
                
            case let .Failed(error):
                failed?(error)
                
            case .Completed:
                completed?()
                
            case .Interrupted:
                interrupted?()
            }
        }
    }
    
    /// Puts a `Next` event into the given observer.
    public func sendNext(_ value: Value) {
        action(.Next(value))
    }
    
    /// Puts an `Failed` event into the given observer.
    public func sendFailed(_ error: Error) {
        action(.Failed(error))
    }
    
    /// Puts a `Completed` event into the given observer.
    public func sendCompleted() {
        action(.Completed)
    }
    
    /// Puts a `Interrupted` event into the given observer.
    public func sendInterrupted() {
        action(.Interrupted)
    }
}
