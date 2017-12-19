//
//  ResponseMiddleware.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 11/22/17.
//

import Foundation
import StreamKit
import Regex
import PathToRegex

struct ResponseMiddleware: HandlerNode {

    weak var parent: Router?
    let transform: ResponseMapper

    func map(responses: Signal<Response>) -> Signal<Response>{
        let results: Signal<Response>
        switch transform {
            case .sync(let syncTransform):
                results = responses.map { response -> Response in
                    syncTransform(response)
                }
            case .async(let asyncTransform):
                results = responses.flatMap { response -> Signal<Response> in
                    return asyncTransform(response).asSignal()
                }
        }
        return results
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
        let (handled, handledInput) = Signal<Response>.pipe()
        map(responses: responses).add(observer: handledInput)
        return (handled, errors, requests)
    }

    init(parent: Router, _ transform: ResponseMapper) {
        self.transform = transform
        self.parent = parent
    }

}

extension ResponseMiddleware: CustomStringConvertible {

    var description: String {
        return "RESPONSE MIDDLEWARE '\(routePath)'"
    }

}

