//
//  Result.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/14/16.
//
//

public enum Result<T, Error: ErrorProtocol>: CustomStringConvertible, CustomDebugStringConvertible {
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