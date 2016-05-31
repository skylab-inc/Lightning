//
//  Disposable.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

/// Represents something that can be “disposed,” usually associated with freeing
/// resources or canceling work.
public protocol Disposable: class {
    /// Whether this disposable has been disposed already.
    var disposed: Bool { get }
    
    func dispose()
}

/// A disposable that only flips `disposed` upon disposal, and performs no other
/// work.
public final class SimpleDisposable: Disposable {
    private var _disposed = false
    
    public var disposed: Bool {
        return _disposed
    }
    
    public init() {}
    
    public func dispose() {
        _disposed = true
    }
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

/// A disposable that will optionally dispose of another disposable.
public final class SerialDisposable: Disposable {
    private struct State {
        var innerDisposable: Disposable? = nil
        var disposed = false
    }
    
    private var state = State()
    
    public var disposed: Bool {
        return state.disposed
    }
    
    /// The inner disposable to dispose of.
    ///
    /// Whenever this property is set (even to the same value!), the previous
    /// disposable is automatically disposed.
    public var innerDisposable: Disposable? {
        get {
            return state.innerDisposable
        }
        
        set(d) {
            var oldState = state
            oldState.innerDisposable = d
            
            oldState.innerDisposable?.dispose()
            if oldState.disposed {
                d?.dispose()
            }
        }
    }
    
    /// Initializes the receiver to dispose of the argument when the
    /// SerialDisposable is disposed.
    public init(_ disposable: Disposable? = nil) {
        innerDisposable = disposable
    }
    
    public func dispose() {
        let orig = state
        state = State(innerDisposable: nil, disposed: true)
        orig.innerDisposable?.dispose()
    }
}