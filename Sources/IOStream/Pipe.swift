//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

import Dispatch
import POSIX
import POSIXExtensions
import Reflex

public final class Pipe: WritableIOStream, ReadableIOStream {
    
    public let fd: POSIXExtensions.FileDescriptor
    public let channel: DispatchIO
    public let channelErrorSignal: Signal<(), SystemError>
    
    public init(fd: StandardFileDescriptor) {
        self.fd = fd
        let (channelErrorSignal, observer) = Signal<(), SystemError>.pipe()
        self.channelErrorSignal = channelErrorSignal
        self.channel = DispatchIO(type: .stream, fileDescriptor: fd.rawValue, queue: .main) { error in
            if let systemError = SystemError(errorNumber: error) {
                observer.sendFailed(systemError)
            } else {
                observer.sendCompleted()
            }
        }
    }
    
}
