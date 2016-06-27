//
//  Status.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/26/16.
//
//
//    The MIT License (MIT)
//
//    Copyright (c) 2016 Swift X
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

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
    case unprocessableEntity
    case locked
    case failedDependency
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
    
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
    
    case other(statusCode: Int, reasonPhrase: String)
}

extension Status {
    public init(statusCode: Int, reasonPhrase: String? = nil) {
        if let reasonPhrase = reasonPhrase {
            self = other(statusCode: statusCode, reasonPhrase: reasonPhrase)
        } else {
            switch statusCode {
            case `continue`.statusCode:                    self = `continue`
            case switchingProtocols.statusCode:            self = switchingProtocols
            case processing.statusCode:                    self = processing
                
            case ok.statusCode:                            self = ok
            case created.statusCode:                       self = created
            case accepted.statusCode:                      self = accepted
            case nonAuthoritativeInformation.statusCode:   self = nonAuthoritativeInformation
            case noContent.statusCode:                     self = noContent
            case resetContent.statusCode:                  self = resetContent
            case partialContent.statusCode:                self = partialContent
                
            case multipleChoices.statusCode:               self = multipleChoices
            case movedPermanently.statusCode:              self = movedPermanently
            case found.statusCode:                         self = found
            case seeOther.statusCode:                      self = seeOther
            case notModified.statusCode:                   self = notModified
            case useProxy.statusCode:                      self = useProxy
            case switchProxy.statusCode:                   self = switchProxy
            case temporaryRedirect.statusCode:             self = temporaryRedirect
            case permanentRedirect.statusCode:             self = permanentRedirect
                
            case badRequest.statusCode:                    self = badRequest
            case unauthorized.statusCode:                  self = unauthorized
            case paymentRequired.statusCode:               self = paymentRequired
            case forbidden.statusCode:                     self = forbidden
            case notFound.statusCode:                      self = notFound
            case methodNotAllowed.statusCode:              self = methodNotAllowed
            case notAcceptable.statusCode:                 self = notAcceptable
            case proxyAuthenticationRequired.statusCode:   self = proxyAuthenticationRequired
            case requestTimeout.statusCode:                self = requestTimeout
            case conflict.statusCode:                      self = conflict
            case gone.statusCode:                          self = gone
            case lengthRequired.statusCode:                self = lengthRequired
            case preconditionFailed.statusCode:            self = preconditionFailed
            case requestEntityTooLarge.statusCode:         self = requestEntityTooLarge
            case requestURITooLong.statusCode:             self = requestURITooLong
            case unsupportedMediaType.statusCode:          self = unsupportedMediaType
            case requestedRangeNotSatisfiable.statusCode:  self = requestedRangeNotSatisfiable
            case expectationFailed.statusCode:             self = expectationFailed
            case imATeapot.statusCode:                     self = imATeapot
            case authenticationTimeout.statusCode:         self = authenticationTimeout
            case enhanceYourCalm.statusCode:               self = enhanceYourCalm
            case unprocessableEntity.statusCode:           self = unprocessableEntity
            case locked.statusCode:                        self = locked
            case failedDependency.statusCode:              self = failedDependency
            case preconditionRequired.statusCode:          self = preconditionRequired
            case tooManyRequests.statusCode:               self = tooManyRequests
            case requestHeaderFieldsTooLarge.statusCode:   self = requestHeaderFieldsTooLarge
                
            case internalServerError.statusCode:           self = internalServerError
            case notImplemented.statusCode:                self = notImplemented
            case badGateway.statusCode:                    self = badGateway
            case serviceUnavailable.statusCode:            self = serviceUnavailable
            case gatewayTimeout.statusCode:                self = gatewayTimeout
            case httpVersionNotSupported.statusCode:       self = httpVersionNotSupported
            case variantAlsoNegotiates.statusCode:         self = variantAlsoNegotiates
            case insufficientStorage.statusCode:           self = insufficientStorage
            case loopDetected.statusCode:                  self = loopDetected
            case notExtended.statusCode:                   self = notExtended
            case networkAuthenticationRequired.statusCode: self = networkAuthenticationRequired
                
            default: self = other(statusCode: statusCode, reasonPhrase: "S4")
            }
        }
    }
}

extension Status {
    public var statusCode: Int {
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
        case .unprocessableEntity:           return 422
        case .locked:                        return 423
        case .failedDependency:              return 424
        case .preconditionRequired:          return 428
        case .tooManyRequests:               return 429
        case .requestHeaderFieldsTooLarge:   return 431
            
        case .internalServerError:           return 500
        case .notImplemented:                return 501
        case .badGateway:                    return 502
        case .serviceUnavailable:            return 503
        case .gatewayTimeout:                return 504
        case .httpVersionNotSupported:       return 505
        case .variantAlsoNegotiates:         return 506
        case .insufficientStorage:           return 507
        case .loopDetected:                  return 508
        case .notExtended:                   return 510
        case .networkAuthenticationRequired: return 511
            
        case .other(let statusCode, _):        return statusCode
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
        case .nonAuthoritativeInformation:   return "Non Authoritative Information"
        case .noContent:                     return "No Content"
        case .resetContent:                  return "Reset Content"
        case .partialContent:                return "Partial Content"
            
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
        case .imATeapot:                     return "I'm A Teapot"
        case .authenticationTimeout:         return "Authentication Timeout"
        case .enhanceYourCalm:               return "Enhance Your Calm"
        case .unprocessableEntity:           return "Unprocessable Entity"
        case .locked:                        return "Locked"
        case .failedDependency:              return "Failed Dependency"
        case .preconditionRequired:          return "PreconditionR equired"
        case .tooManyRequests:               return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:   return "Request Header Fields Too Large"
            
        case .internalServerError:           return "Internal Server Error"
        case .notImplemented:                return "Not Implemented"
        case .badGateway:                    return "Bad Gateway"
        case .serviceUnavailable:            return "Service Unavailable"
        case .gatewayTimeout:                return "Gateway Timeout"
        case .httpVersionNotSupported:       return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:         return "Variant Also Negotiates"
        case .insufficientStorage:           return "Insufficient Storage"
        case .loopDetected:                  return "Loop Detected"
        case .notExtended:                   return "Not Extended"
        case .networkAuthenticationRequired: return "Network Authentication Required"
            
        case .other(_, let reasonPhrase):      return reasonPhrase
        }
    }
}

extension Status: Hashable {
    public var hashValue: Int {
        return statusCode
    }
}

public func ==(lhs: Status, rhs: Status) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
