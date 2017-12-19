//
//  ErrorEndpoint.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 12/18/17.
//

import Foundation
import StreamKit
import Regex
import PathToRegex

struct ErrorEndpoint: HandlerNode {

    let handler: ErrorHandler
    weak var parent: Router?
    let method: Method?

    func setParameters(on request: Request, match: Match) {
        request.parameters = [:]
    }

    func shouldHandleAndAddParams(request: Request, error: Error) -> Bool {
        if let method = method, request.method != method {
            return false
        }
        return true
    }

    func handle(
        requests: Signal<Request>,
        errors: Signal<(Request, Error)>,
        responses: Signal<Response>
        ) -> (
        handled: Signal<Response>,
        errored: Signal<(Request, Error)>,
        unhandled: Signal<Request>
        ) {
            let (shouldHandle, unhandled) = errors.partition(self.shouldHandleAndAddParams)
            let (handled, errored) = handle(errors: shouldHandle)

            let (mergedResponses, responsesInput) = Signal<Response>.pipe()
            responses.add(observer: responsesInput)
            handled.add(observer: responsesInput)

            let (mergedErrored, erroredInput) = Signal<(Request, Error)>.pipe()
            unhandled.add(observer: erroredInput)
            errored.add(observer: erroredInput)

            return (mergedResponses, mergedErrored, requests)
    }

    init(parent: Router? = nil, method: Method? = nil, _ handler: ErrorHandler) {
        self.handler = handler
        self.method = method
        self.parent = parent
    }

}

extension ErrorEndpoint {

    func handle(errors: Signal<(Request, Error)>) -> (Signal<Response>, Signal<(Request, Error)>) {
        let responses: Signal<Response>
        let (newErrors, newErrorsInput) = Signal<(Request, Error)>.pipe()
        switch handler {
        case .sync(let syncTransform):
            responses = errors.flatMap { (request, error) -> Response? in
                do {
                    let response = try syncTransform(request, error)
                    response.request = request
                    return response
                } catch {
                    newErrorsInput.sendNext((request, error))
                    return nil
                }
            }
        case .async(let asyncTransform):
            responses = errors.flatMap { (request, error) -> Signal<Response?> in
                return Signal { observer in
                    asyncTransform(request, error).then {
                        $0.request = request
                        observer.sendNext($0)
                        observer.sendCompleted()
                    }.catch { error in
                        newErrorsInput.sendNext((request, error))
                        observer.sendNext(nil)
                        observer.sendCompleted()
                    }
                    return nil
                }
            }.flatMap { (response: Response?) in response }
        }
        return (responses, newErrors)
    }

}

extension ErrorEndpoint: CustomStringConvertible {
    var description: String {
        if let method = method {
            return "\(method) '\(routePath)'"
        }
        return "ERROR '\(routePath)'"
    }

}
