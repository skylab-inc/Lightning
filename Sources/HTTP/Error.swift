//
//  Error.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/16/16.
//
//

public protocol HTTPError: Error {
    var status: Status { get }
}

public enum ClientError: HTTPError {
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case requestEntityTooLarge
    case requestURITooLong
    case unsupportedMediaType
    case requestedRangeNotSatisfiable
    case expectationFailed
    case imATeapot
    case authenticationTimeout
    case enhanceYourCalm
    case unprocessableEntity
    case locked
    case failedDependency
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
}

extension ClientError {
    public var status: Status {
        switch self {
        case .badRequest:                   return Status.badRequest
        case .unauthorized:                 return Status.unauthorized
        case .paymentRequired:              return Status.paymentRequired
        case .forbidden:                    return Status.forbidden
        case .notFound:                     return Status.notFound
        case .methodNotAllowed:             return Status.methodNotAllowed
        case .notAcceptable:                return Status.notAcceptable
        case .proxyAuthenticationRequired:  return Status.proxyAuthenticationRequired
        case .requestTimeout:               return Status.requestTimeout
        case .conflict:                     return Status.conflict
        case .gone:                         return Status.gone
        case .lengthRequired:               return Status.lengthRequired
        case .preconditionFailed:           return Status.preconditionFailed
        case .requestEntityTooLarge:        return Status.requestEntityTooLarge
        case .requestURITooLong:            return Status.requestURITooLong
        case .unsupportedMediaType:         return Status.unsupportedMediaType
        case .requestedRangeNotSatisfiable: return Status.requestedRangeNotSatisfiable
        case .expectationFailed:            return Status.expectationFailed
        case .imATeapot:                    return Status.imATeapot
        case .authenticationTimeout:        return Status.authenticationTimeout
        case .enhanceYourCalm:              return Status.enhanceYourCalm
        case .unprocessableEntity:          return Status.unprocessableEntity
        case .locked:                       return Status.locked
        case .failedDependency:             return Status.failedDependency
        case .preconditionRequired:         return Status.preconditionRequired
        case .tooManyRequests:              return Status.tooManyRequests
        case .requestHeaderFieldsTooLarge:  return Status.requestHeaderFieldsTooLarge
        }
    }
}

public enum ServerError: HTTPError {
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended
    case networkAuthenticationRequired
}

extension ServerError {
    public var status: Status {
        switch self {
        case .internalServerError:           return Status.internalServerError
        case .notImplemented:                return Status.notImplemented
        case .badGateway:                    return Status.badGateway
        case .serviceUnavailable:            return Status.serviceUnavailable
        case .gatewayTimeout:                return Status.gatewayTimeout
        case .httpVersionNotSupported:       return Status.httpVersionNotSupported
        case .variantAlsoNegotiates:         return Status.variantAlsoNegotiates
        case .insufficientStorage:           return Status.insufficientStorage
        case .loopDetected:                  return Status.loopDetected
        case .notExtended:                   return Status.notExtended
        case .networkAuthenticationRequired: return Status.networkAuthenticationRequired
        }
    }
}
