//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

public struct Pipe: IOStream {
    
    let loop: RunLoop
    let fd: FileDescriptor
    
    init(loop: RunLoop, fd: StandardFileDescriptor) {
        self.loop = loop
        self.fd = fd
    }
    
}