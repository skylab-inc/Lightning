//
//  Disposable.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

/// Represents something that can be “disposed,” usually associated with freeing
/// resources or canceling work.
public protocol Disposable {
    /// Whether this disposable has been disposed already.
    var disposed: Bool { get }

    func dispose()
}

/// A disposable that will run an action upon disposal.
public final class ActionDisposable: Disposable {
    var action: (() -> Void)?
    
    public var disposed: Bool {
        return action == nil
    }
    
    /// Initializes the disposable to run the given action upon disposal.
    public init(action: (() -> Void)?) {
        self.action = action
    }
    
    public func dispose() {
        let oldAction = action
        action = nil
        oldAction?()
    }
}

/// A disposable that, upon deinitialization, will automatically dispose of
/// another disposable.
public final class ScopedDisposable: Disposable {
    
    /// The disposable which will be disposed when the ScopedDisposable
    /// deinitializes.
    public let innerDisposable: Disposable
    
    public var disposed: Bool {
        return innerDisposable.disposed
    }
    
    /// Initializes the receiver to dispose of the argument upon
    /// deinitialization.
    public init(_ disposable: Disposable) {
        innerDisposable = disposable
    }
    
    deinit {
        dispose()
    }
    
    public func dispose() {
        innerDisposable.dispose()
    }
}
