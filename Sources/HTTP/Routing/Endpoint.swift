//
//  Endpoint.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 11/22/17.
//

import Foundation
import StreamKit
import Regex
import PathToRegex

struct Endpoint: HandlerNode {

    let handler: RequestHandler
    weak var parent: Router?
    let method: Method?

    func setParameters(on request: Request, match: Match) {
        request.parameters = [:]
    }

    func shouldHandleAndAddParams(request: Request) -> Bool {
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
        let (shouldHandle, unhandled) = requests.partition(self.shouldHandleAndAddParams)
        let (handled, errored) = handle(requests: shouldHandle)

        let (mergedResponses, responsesInput) = Signal<Response>.pipe()
        responses.add(observer: responsesInput)
        handled.add(observer: responsesInput)

        let (mergedErrored, erroredInput) = Signal<(Request, Error)>.pipe()
        errors.add(observer: erroredInput)
        errored.add(observer: erroredInput)

        return (mergedResponses, mergedErrored, unhandled)
    }

    init(parent: Router? = nil, method: Method? = nil, _ handler: RequestHandler) {
        self.handler = handler
        self.method = method
        self.parent = parent
    }

}

extension Endpoint {

    func handle(requests: Signal<Request>) -> (Signal<Response>, Signal<(Request, Error)>) {
        let responses: Signal<Response>
        let (errors, errorsInput) = Signal<(Request, Error)>.pipe()
        switch handler {
            case .sync(let syncTransform):
                responses = requests.flatMap { request -> Response? in
                    do {
                        let response = try syncTransform(request)
                        response.request = request
                        return response
                    } catch {
                        errorsInput.sendNext((request, error))
                        return nil
                    }
                }
            case .async(let asyncTransform):
                responses = requests.flatMap { request -> Signal<Response?> in
                    return Signal { observer in
                        asyncTransform(request).then {
                            $0.request = request
                            observer.sendNext($0)
                            observer.sendCompleted()
                        }.catch { error in
                            errorsInput.sendNext((request, error))
                            observer.sendNext(nil)
                            observer.sendCompleted()
                        }
                        return nil
                    }
                }.flatMap { (response: Response?) in response }
        }
        return (responses, errors)
    }

}

extension Endpoint: CustomStringConvertible {
    var description: String {
        if let method = method {
            return "\(method) '\(routePath)'"
        }
        return "ANY '\(routePath)'"
    }

}
