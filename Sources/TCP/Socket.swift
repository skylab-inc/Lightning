//
//  File.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/8/16.
//
//

import Dispatch
import Reflex
import POSIX
import POSIXExtensions
import IOStream
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public final class Socket: WritableIOStream, ReadableIOStream {
    private static let defaultReuseAddress = true

    private let socketFD: SocketFileDescriptor
    public var fd: POSIXExtensions.FileDescriptor {
        return socketFD
    }
    public let channel: DispatchIO

    public convenience init() throws {
        let fd = try SocketFileDescriptor(
            socketType: SocketType.stream,
            addressFamily: AddressFamily.inet
        )
        try self.init(fd: fd)
    }

    public init(fd: SocketFileDescriptor, reuseAddress: Bool = defaultReuseAddress) throws {
        self.socketFD = fd

        if reuseAddress {
            // Set SO_REUSEADDR
            var reuseAddr = 1
            let error = setsockopt(
                self.socketFD.rawValue,
                SOL_SOCKET,
                SO_REUSEADDR,
                &reuseAddr,
                socklen_t(MemoryLayout<Int>.stride)
            )
            if let systemError = SystemError(errorNumber: error) {
                throw systemError
            }
        }

        // Create the dispatch source for listening
        self.channel = DispatchIO(
            type: .stream,
            fileDescriptor: fd.rawValue,
            queue: .main
        ) { error in
            if let systemError = SystemError(errorNumber: error) {
                try! { throw systemError }()
            }
        }
    }

    public func connect(host: String, port: Port) -> Source<Socket, SystemError> {
        return Source { [socketFD, fd, channel = self.channel] observer in
            var addrInfoPointer: UnsafeMutablePointer<addrinfo>? = nil

            var hints = systemCreateAddressInfo(
                ai_flags: 0,
                ai_family: socketFD.addressFamily.rawValue,
                ai_socktype: POSIXExtensions.SOCK_STREAM,
                ai_protocol: POSIXExtensions.IPPROTO_TCP,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )

            let ret = getaddrinfo(host, String(port), &hints, &addrInfoPointer)
            if let systemError = SystemError(errorNumber: ret) {
                observer.sendFailed(systemError)
                return nil
            }

            let addressInfo = addrInfoPointer!.pointee
            let connectRet = systemConnect(
                fd.rawValue,
                addressInfo.ai_addr,
                socklen_t(MemoryLayout<sockaddr>.stride)
            )
            freeaddrinfo(addrInfoPointer)

            // Blocking, connect immediately or throw error
            if socketFD.blocking {
                if connectRet != 0 {
                    observer.sendFailed(SystemError(errorNumber: errno)!)
                } else {
                    observer.sendCompleted()
                }
                return nil
            }

            // Non-blocking, check for immediate connection
            if connectRet == 0 {
                observer.sendCompleted()
                return nil
            }

            // Non-blocking, dispatch connection, check errno for connection error.
            let error = SystemError(errorNumber: errno)
            if case SystemError.operationNowInProgress? = error {
                // Wait for channel to be writable. Then we are connected.
                channel.write(offset: off_t(), data: .empty, queue: .main) { done, data, error in
                    var result = 0
                    var resultLength = socklen_t(MemoryLayout<Int>.stride)
                    let ret = getsockopt(fd.rawValue, SOL_SOCKET, SO_ERROR, &result, &resultLength)
                    if let systemError = SystemError(errorNumber: ret) {
                        observer.sendFailed(systemError)
                        return
                    }
                    if let systemError = SystemError(errorNumber: Int32(result)) {
                        observer.sendFailed(systemError)
                        return
                    }
                    if let systemError = SystemError(errorNumber: error) {
                        observer.sendFailed(systemError)
                        return
                    }
                    observer.sendNext(self)
                    observer.sendCompleted()
                }
            } else if let error = error {
                observer.sendFailed(error)
            }
            return ActionDisposable {
                channel.close()
            }
        }
    }
}
