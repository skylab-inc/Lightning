//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

import Dispatch

public class Pipe: IOStream {
    
    public let loop: RunLoop
    public let fd: FileDescriptor
    public let channel: dispatch_io_t
    
    public var readListeners: [(result: [UInt8]) -> ()] = []
    
    public var writeListeners: [(unwrittenData: [UInt8]?) -> ()] = []
    
    public var closeListeners: [(error: Error?) -> ()] = []
    
    public var writingCompleteListeners: [(error: Error?) -> ()] = []
    
    public init(loop: RunLoop, fd: StandardFileDescriptor) {
        self.loop = loop
        self.fd = fd
        self.channel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                try! { throw Error(rawValue: error) }()
            }
        }
    }
}