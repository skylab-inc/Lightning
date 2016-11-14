//
//  Status.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/16/16.
//
//

import Foundation

public enum Status {
    case `continue`
    case switchingProtocols
    case processing

    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case imUsed

    case multipleChoices
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect

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
    case misdirectedRequest
    case unprocessableEntity
    case locked
    case failedDependency
    case unorderedCollection
    case upgradeRequired
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
    case unavailableForLegalReasons

    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case bandwidthLimitExceeded
    case notExtended
    case networkAuthenticationRequired

    case other(code: Int, reasonPhrase: String)
}

extension Status {
    public init(code: Int, reasonPhrase: String? = nil) {
        if let reasonPhrase = reasonPhrase {
            self = .other(code: code, reasonPhrase: reasonPhrase)
        } else {
            switch code {
            case Status.`continue`.code:                    self = .`continue`
            case Status.switchingProtocols.code:            self = .switchingProtocols
            case Status.processing.code:                    self = .processing

            case Status.ok.code:                            self = .ok
            case Status.created.code:                       self = .created
            case Status.accepted.code:                      self = .accepted
            case Status.nonAuthoritativeInformation.code:   self = .nonAuthoritativeInformation
            case Status.noContent.code:                     self = .noContent
            case Status.resetContent.code:                  self = .resetContent
            case Status.partialContent.code:                self = .partialContent
            case Status.alreadyReported.code:               self = .alreadyReported
            case Status.multiStatus.code:                   self = .multiStatus
            case Status.imUsed.code:                        self = .imUsed

            case Status.multipleChoices.code:               self = .multipleChoices
            case Status.movedPermanently.code:              self = .movedPermanently
            case Status.found.code:                         self = .found
            case Status.seeOther.code:                      self = .seeOther
            case Status.notModified.code:                   self = .notModified
            case Status.useProxy.code:                      self = .useProxy
            case Status.switchProxy.code:                   self = .switchProxy
            case Status.temporaryRedirect.code:             self = .temporaryRedirect
            case Status.permanentRedirect.code:             self = .permanentRedirect

            case Status.badRequest.code:                    self = .badRequest
            case Status.unauthorized.code:                  self = .unauthorized
            case Status.paymentRequired.code:               self = .paymentRequired
            case Status.forbidden.code:                     self = .forbidden
            case Status.notFound.code:                      self = .notFound
            case Status.methodNotAllowed.code:              self = .methodNotAllowed
            case Status.notAcceptable.code:                 self = .notAcceptable
            case Status.proxyAuthenticationRequired.code:   self = .proxyAuthenticationRequired
            case Status.requestTimeout.code:                self = .requestTimeout
            case Status.conflict.code:                      self = .conflict
            case Status.gone.code:                          self = .gone
            case Status.lengthRequired.code:                self = .lengthRequired
            case Status.preconditionFailed.code:            self = .preconditionFailed
            case Status.requestEntityTooLarge.code:         self = .requestEntityTooLarge
            case Status.requestURITooLong.code:             self = .requestURITooLong
            case Status.unsupportedMediaType.code:          self = .unsupportedMediaType
            case Status.requestedRangeNotSatisfiable.code:  self = .requestedRangeNotSatisfiable
            case Status.expectationFailed.code:             self = .expectationFailed
            case Status.imATeapot.code:                     self = .imATeapot
            case Status.authenticationTimeout.code:         self = .authenticationTimeout
            case Status.enhanceYourCalm.code:               self = .enhanceYourCalm
            case Status.misdirectedRequest.code:            self = .misdirectedRequest
            case Status.unprocessableEntity.code:           self = .unprocessableEntity
            case Status.locked.code:                        self = .locked
            case Status.failedDependency.code:              self = .failedDependency
            case Status.unorderedCollection.code:           self = .unorderedCollection
            case Status.upgradeRequired.code:               self = .upgradeRequired
            case Status.preconditionRequired.code:          self = .preconditionRequired
            case Status.tooManyRequests.code:               self = .tooManyRequests
            case Status.requestHeaderFieldsTooLarge.code:   self = .requestHeaderFieldsTooLarge
            case Status.unavailableForLegalReasons.code:    self = .unavailableForLegalReasons

            case Status.internalServerError.code:           self = .internalServerError
            case Status.notImplemented.code:                self = .notImplemented
            case Status.badGateway.code:                    self = .badGateway
            case Status.serviceUnavailable.code:            self = .serviceUnavailable
            case Status.gatewayTimeout.code:                self = .gatewayTimeout
            case Status.httpVersionNotSupported.code:       self = .httpVersionNotSupported
            case Status.variantAlsoNegotiates.code:         self = .variantAlsoNegotiates
            case Status.insufficientStorage.code:           self = .insufficientStorage
            case Status.loopDetected.code:                  self = .loopDetected
            case Status.bandwidthLimitExceeded.code:        self = .bandwidthLimitExceeded
            case Status.notExtended.code:                   self = .notExtended
            case Status.networkAuthenticationRequired.code: self = .networkAuthenticationRequired

            default: self = .other(code: code, reasonPhrase: "¯\\_(ツ)_/¯")
            }
        }
    }
}

extension Status {
    public var code: Int {
        switch self {
        case .`continue`:                    return 100
        case .switchingProtocols:            return 101
        case .processing:                    return 102

        case .ok:                            return 200
        case .created:                       return 201
        case .accepted:                      return 202
        case .nonAuthoritativeInformation:   return 203
        case .noContent:                     return 204
        case .resetContent:                  return 205
        case .partialContent:                return 206
        case .multiStatus:                   return 207
        case .alreadyReported:               return 208
        case .imUsed:                        return 226

        case .multipleChoices:               return 300
        case .movedPermanently:              return 301
        case .found:                         return 302
        case .seeOther:                      return 303
        case .notModified:                   return 304
        case .useProxy:                      return 305
        case .switchProxy:                   return 306
        case .temporaryRedirect:             return 307
        case .permanentRedirect:             return 308

        case .badRequest:                    return 400
        case .unauthorized:                  return 401
        case .paymentRequired:               return 402
        case .forbidden:                     return 403
        case .notFound:                      return 404
        case .methodNotAllowed:              return 405
        case .notAcceptable:                 return 406
        case .proxyAuthenticationRequired:   return 407
        case .requestTimeout:                return 408
        case .conflict:                      return 409
        case .gone:                          return 410
        case .lengthRequired:                return 411
        case .preconditionFailed:            return 412
        case .requestEntityTooLarge:         return 413
        case .requestURITooLong:             return 414
        case .unsupportedMediaType:          return 415
        case .requestedRangeNotSatisfiable:  return 416
        case .expectationFailed:             return 417
        case .imATeapot:                     return 418
        case .authenticationTimeout:         return 419
        case .enhanceYourCalm:               return 420
        case .misdirectedRequest:            return 421
        case .unprocessableEntity:           return 422
        case .locked:                        return 423
        case .failedDependency:              return 424
        case .unorderedCollection:           return 425
        case .upgradeRequired:               return 426
        case .preconditionRequired:          return 428
        case .tooManyRequests:               return 429
        case .requestHeaderFieldsTooLarge:   return 431
        case .unavailableForLegalReasons:    return 451

        case .internalServerError:           return 500
        case .notImplemented:                return 501
        case .badGateway:                    return 502
        case .serviceUnavailable:            return 503
        case .gatewayTimeout:                return 504
        case .httpVersionNotSupported:       return 505
        case .variantAlsoNegotiates:         return 506
        case .insufficientStorage:           return 507
        case .loopDetected:                  return 508
        case .bandwidthLimitExceeded:        return 509
        case .notExtended:                   return 510
        case .networkAuthenticationRequired: return 511

        case .other(let code, _):        return code
        }
    }
}

extension Status {
    public var reasonPhrase: String {
        switch self {
        case .`continue`:                    return "Continue"
        case .switchingProtocols:            return "Switching Protocols"
        case .processing:                    return "Processing"

        case .ok:                            return "OK"
        case .created:                       return "Created"
        case .accepted:                      return "Accepted"
        case .nonAuthoritativeInformation:   return "Non-Authoritative Information"
        case .noContent:                     return "No Content"
        case .resetContent:                  return "Reset Content"
        case .partialContent:                return "Partial Content"
        case .multiStatus:                   return "Multi-Status"
        case .alreadyReported:               return "Already Reported"
        case .imUsed:                        return "IM Used"

        case .multipleChoices:               return "Multiple Choices"
        case .movedPermanently:              return "Moved Permanently"
        case .found:                         return "Found"
        case .seeOther:                      return "See Other"
        case .notModified:                   return "Not Modified"
        case .useProxy:                      return "Use Proxy"
        case .switchProxy:                   return "Switch Proxy"
        case .temporaryRedirect:             return "Temporary Redirect"
        case .permanentRedirect:             return "Permanent Redirect"

        case .badRequest:                    return "Bad Request"
        case .unauthorized:                  return "Unauthorized"
        case .paymentRequired:               return "Payment Required"
        case .forbidden:                     return "Forbidden"
        case .notFound:                      return "Not Found"
        case .methodNotAllowed:              return "Method Not Allowed"
        case .notAcceptable:                 return "Not Acceptable"
        case .proxyAuthenticationRequired:   return "Proxy Authentication Required"
        case .requestTimeout:                return "Request Timeout"
        case .conflict:                      return "Conflict"
        case .gone:                          return "Gone"
        case .lengthRequired:                return "Length Required"
        case .preconditionFailed:            return "Precondition Failed"
        case .requestEntityTooLarge:         return "Request Entity Too Large"
        case .requestURITooLong:             return "Request URI Too Long"
        case .unsupportedMediaType:          return "Unsupported Media Type"
        case .requestedRangeNotSatisfiable:  return "Requested Range Not Satisfiable"
        case .expectationFailed:             return "Expectation Failed"
        case .imATeapot:                     return "I'm a teapot"
        case .authenticationTimeout:         return "Authentication Timeout"
        case .enhanceYourCalm:               return "Enhance Your Calm"
        case .misdirectedRequest:            return "Misdirected Request"
        case .unprocessableEntity:           return "Unprocessable Entity"
        case .locked:                        return "Locked"
        case .failedDependency:              return "Failed Dependency"
        case .unorderedCollection:           return "Unordered Collection"
        case .upgradeRequired:               return "Upgrade Required"
        case .preconditionRequired:          return "Precondition Required"
        case .tooManyRequests:               return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:   return "Request Header Fields Too Large"
        case .unavailableForLegalReasons:    return "Unavailable For Legal Reasons"

        case .internalServerError:           return "Internal Server Error"
        case .notImplemented:                return "Not Implemented"
        case .badGateway:                    return "Bad Gateway"
        case .serviceUnavailable:            return "Service Unavailable"
        case .gatewayTimeout:                return "Gateway Timeout"
        case .httpVersionNotSupported:       return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:         return "Variant Also Negotiates"
        case .insufficientStorage:           return "Insufficient Storage"
        case .loopDetected:                  return "Loop Detected"
        case .bandwidthLimitExceeded:        return "Bandwidth Limit Exceeded"
        case .notExtended:                   return "Not Extended"
        case .networkAuthenticationRequired: return "Network Authentication Required"

        case .other(_, let reasonPhrase):      return reasonPhrase
        }
    }
}

extension Status: Hashable {
    public var hashValue: Int {
        return code
    }
}

public func == (lhs: Status, rhs: Status) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
