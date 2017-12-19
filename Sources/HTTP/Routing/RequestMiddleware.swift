//
//  RequestMiddleware.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 11/22/17.
//

import Foundation
import StreamKit
import Regex
import PathToRegex

struct RequestMiddleware: HandlerNode {

    weak var parent: Router?
    let transform: RequestMapper

    func map(requests: Signal<Request>) -> Signal<Request>{
        let results: Signal<Request>
        switch transform {
            case .sync(let syncTransform):
                results = requests.map { request -> Request in
                    syncTransform(request)
                }
            case .async(let asyncTransform):
                results = requests.flatMap { request -> Signal<Request> in
                    return asyncTransform(request).asSignal()
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
        let (unhandled, unhandledInput) = Signal<Request>.pipe()
        map(requests: requests).add(observer: unhandledInput)
        return (responses, errors, unhandled)
    }

    init(parent: Router, _ transform: RequestMapper) {
        self.transform = transform
        self.parent = parent
    }

}

extension RequestMiddleware: CustomStringConvertible {

    var description: String {
        return "REQUEST MIDDLEWARE '\(routePath)'"
    }

}
