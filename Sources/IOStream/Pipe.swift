//
//  Pipe.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

import Dispatch
import POSIX
import StreamKit

public final class Pipe: WritableIOStream, ReadableIOStream {

    public let fd: FileDescriptor
    public let channel: DispatchIO
    public let channelErrorSignal: Signal<()>

    public init(fd: StandardFileDescriptor) {
        self.fd = fd
        let (channelErrorSignal, observer) = Signal<()>.pipe()
        self.channelErrorSignal = channelErrorSignal
        self.channel = DispatchIO(
            type: .stream,
            fileDescriptor: fd.rawValue,
            queue: .main
        ) { error in
            if let systemError = SystemError(errorNumber: error) {
                observer.sendFailed(systemError)
            } else {
                observer.sendCompleted()
            }
        }
    }

}
