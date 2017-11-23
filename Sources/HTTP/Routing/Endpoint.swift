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
        responses: Signal<Response>
    ) -> (
        handled: Signal<Response>,
        unhandled: Signal<Request>
    ) {
        let (handled, handledInput) = Signal<Response>.pipe()
        let (shouldHandle, unhandled) = requests.partition(self.shouldHandleAndAddParams)

        handle(requests: shouldHandle).add(observer: handledInput)

        responses.add(observer: handledInput)
        return (handled, unhandled)
    }

    init(parent: Router? = nil, method: Method? = nil, _ handler: RequestHandler) {
        self.handler = handler
        self.method = method
        self.parent = parent
    }

}

extension Endpoint: ServerDelegate {

    func handle(requests: Signal<Request>) -> Signal<Response> {
        let responses: Signal<Response>
        switch handler {
            case .sync(let syncTransform):
                responses = requests.map { request -> Response in
                    do {
                        return try syncTransform(request)
                    } catch {
                        // TODO: Create a nice error handling scheme.
                        return Response(status: .internalServerError)
                    }
                }
            case .async(let asyncTransform):
                responses = requests.flatMap { request -> Signal<Response> in
                    return Signal { observer in
                        asyncTransform(request).then {
                            observer.sendNext($0)
                            observer.sendCompleted()
                        }.catch { _ in
                            let errorResponse = Response(status: .internalServerError)
                            observer.sendNext(errorResponse)
                            observer.sendCompleted()
                        }
                        return nil
                    }
                }
        }
        return responses
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
