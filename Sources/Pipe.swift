//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

import Dispatch
import RxSwift
import Foundation

public final class Pipe: WritableIOStream, ReadableIOStream {
    
    public let loop: RunLoop
    public let fd: FileDescriptor
    public let channel: dispatch_io_t
    
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