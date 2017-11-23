//
//  Path.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 11/22/17.
//

import Foundation

enum Path {

    // See https://github.com/nodejs/node/blob/master/lib/path.js#L1238
    static func join(_ paths: String...) -> String {
        let joined = paths.filter { path in
            path.count > 0
        }.joined(separator: "/")
        return normalize(path: joined.count > 0 ? joined : ".")
    }

    static func normalize(path: String) -> String {
        return NSString(string: path).standardizingPath
    }

}
