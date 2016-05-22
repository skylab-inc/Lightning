//
//  File.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/8/16.
//
//

import Dispatch
import RxSwift

public final class TCPSocket: WritableIOStream, ReadableIOStream {
    
    public let loop: RunLoop
    private let socketFD: SocketFileDescriptor
    public var fd: FileDescriptor {
        return socketFD
    }
    public let channel: dispatch_io_t
    
    public convenience init(loop: RunLoop) {
        self.init(loop: loop, fd: SocketFileDescriptor(socketType: SocketType.stream, addressFamily: AddressFamily.inet))
    }
    
    public init(loop: RunLoop, fd: SocketFileDescriptor) {
        self.loop = loop
        self.socketFD = fd
        
        // Set SO_REUSEADDR
        var reuseAddr = 1
        let error = setsockopt(self.socketFD.rawValue, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(strideof(Int)))
        if error != 0 {
            try! { throw Error(rawValue: error) }()
        }
        
        // Create the dispatch source for listening
        self.channel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                try! { throw Error(rawValue: error) }()
            }
        }
    }
    
    public func connect(host: String, port: Port) -> Observable<()> {
        return Observable.create { [socketFD, fd, channel] observer in
            var addrInfoPointer = UnsafeMutablePointer<addrinfo>(nil)
            
            var hints = addrinfo(
                ai_flags: 0,
                ai_family: socketFD.addressFamily.rawValue,
                ai_socktype: SOCK_STREAM,
                ai_protocol: IPPROTO_TCP,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
            
            let ret = getaddrinfo(host, String(port), &hints, &addrInfoPointer)
            if ret != 0 {
                observer.onError(error: AddressFamilyError(rawValue: ret))
                return NopDisposable.instance
            }
            
            let addressInfo = addrInfoPointer!.pointee
            let connectRet = system_connect(fd.rawValue, addressInfo.ai_addr, socklen_t(strideof(sockaddr)))
            freeaddrinfo(addrInfoPointer)
            
            // Blocking, connect immediately or throw error
            if socketFD.blocking {
                if connectRet != 0 {
                    observer.onError(error: Error(rawValue: errno))
                } else {
                    observer.onCompleted()
                }
                return NopDisposable.instance
            }
            
            // Non-blocking, check for immediate connection
            if connectRet == 0 {
                observer.onCompleted()
                return NopDisposable.instance
            }
            
            // Non-blocking, dispatch connection, check errno for connection error.
            let error = Error(rawValue: errno)
            if case Error.inProgress = error {
                // Wait for channel to be writable. Then we are connected.
                dispatch_io_write(channel, off_t(), dispatch_data_empty, dispatch_get_main_queue()) { done, data, error in
                    var result = 0
                    var resultLength = socklen_t(strideof(result.dynamicType))
                    let ret = getsockopt(self.fd.rawValue, SOL_SOCKET, SO_ERROR, &result, &resultLength)
                    if ret != 0 {
                        observer.onError(error: Error(rawValue: ret))
                        return
                    }
                    if result != 0 {
                        observer.onError(error: Error(rawValue: Int32(result)))
                        return
                    }
                    log.debug("Connection established on \(self.fd)")
                    observer.onCompleted()
                }
            } else {
                observer.onError(error: error)
            }
            return AnonymousDisposable {
                dispatch_io_close(channel, 0)
            }
        }
    }
}