//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

public struct Pipe: IOStream {
    
    public let loop: RunLoop
    public let fd: FileDescriptor
    
    public init(loop: RunLoop, fd: StandardFileDescriptor) {
        self.loop = loop
        self.fd = fd
    }
    
}