//
//  Filter.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 11/22/17.
//

import Foundation
import StreamKit
import Regex
import PathToRegex

struct Filter: FilterNode, CustomStringConvertible {

    weak var parent: Router?
    var predicate: (Request) -> Bool

    func filter(
        requests: Signal<Request>
    ) -> (
        requests: Signal<Request>,
        filtered: Signal<Request>
    ) {
        return requests.partition(predicate)
    }

    init(parent: Router? = nil, predicate: @escaping (Request) -> Bool) {
        self.parent = parent
        self.predicate = predicate
    }

    var description: String {
        return "FILTER '\(routePath)'"
    }

}
