//
//  Result.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/14/16.
//
//

public enum Result<T, Error: ErrorProtocol>: ResultType, CustomStringConvertible, CustomDebugStringConvertible {
    case Success(T)
    case Failure(Error)
    
    // MARK: Constructors
    
    /// Constructs a success wrapping a `value`.
    public init(value: T) {
        self = .Success(value)
    }
    
    /// Constructs a failure wrapping an `error`.
    public init(error: Error) {
        self = .Failure(error)
    }
    
    public var description: String {
        return analysis(
            ifSuccess: { ".Success(\($0))" },
            ifFailure: { ".Failure(\($0))" })
    }
    
    public func analysis<Result>(ifSuccess: @noescape (T) -> Result, ifFailure: @noescape (Error) -> Result) -> Result {
        switch self {
        case let .Success(value):
            return ifSuccess(value)
        case let .Failure(value):
            return ifFailure(value)
        }
    }
    
    // MARK: CustomDebugStringConvertible
    
    public var debugDescription: String {
        return description
    }
}

public extension ResultType {
    
    /// Returns the value if self represents a success, `nil` otherwise.
    public var value: Value? {
        return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
    }
    
    /// Returns the error if self represents a failure, `nil` otherwise.
    public var error: Error? {
        return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
    }
    
}

/// A type that can represent either failure with an error or success with a result value.
public protocol ResultType {
    associatedtype Value
    associatedtype Error: ErrorProtocol
    
    /// Constructs a successful result wrapping a `value`.
    init(value: Value)
    
    /// Constructs a failed result wrapping an `error`.
    init(error: Error)
    
    /// Case analysis for ResultType.
    ///
    /// Returns the value produced by appliying `ifFailure` to the error if self represents a failure, or `ifSuccess` to the result value if self represents a success.
    func analysis<U>(ifSuccess: @noescape (Value) -> U, ifFailure: @noescape (Error) -> U) -> U
    
    /// Returns the value if self represents a success, `nil` otherwise.
    ///
    /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
    var value: Value? { get }
    
    /// Returns the error if self represents a failure, `nil` otherwise.
    ///
    /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
    var error: Error? { get }
}