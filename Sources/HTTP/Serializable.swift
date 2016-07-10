//
//  Serializable.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 7/1/16.
//
//

public protocol Serializable {
    var serialized: [UInt8] { get }
}
