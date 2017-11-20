//
//  Serializable.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 7/1/16.
//
//
import Foundation

public protocol Serializable {
    var serialized: Data { get }
}
