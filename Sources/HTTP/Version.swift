//
//  Version.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/16/16.
//
//

import Foundation

public struct Version {
    public var major: Int
    public var minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }
}
