//
//  File.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/8/16.
//
//
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Dispatch
import StreamKit
import POSIX
import IOStream
import PromiseKit

public final class Socket: WritableIOStream, ReadableIOStream {
    public static let defaultReuseAddress = false
    public static let defaultReusePort = false

    private let socketFD: SocketFileDescriptor
    public var fd: FileDescriptor {
        return socketFD
    }
    public let channel: DispatchIO

    public convenience init(reuseAddress: Bool = defaultReuseAddress, reusePort: Bool = defaultReusePort) throws {
        let fd = try SocketFileDescriptor(
            socketType: SocketType.stream,
            addressFamily: AddressFamily.inet
        )
        try self.init(fd: fd, reuseAddress: reuseAddress, reusePort: reusePort)
    }

    public init(fd: SocketFileDescriptor, reuseAddress: Bool = defaultReuseAddress, reusePort: Bool = defaultReusePort) throws {
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

        if reusePort {
            // Set SO_REUSEPORT
            var reusePort = 1
            let error = setsockopt(
                self.socketFD.rawValue,
                SOL_SOCKET,
                SO_REUSEPORT,
                &reusePort,
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
            // Close the file descriptor for the channel
            // fd.close()

            // Throw any error
            if let systemError = SystemError(errorNumber: error) {
                try! { throw systemError }()
            }
        }
    }

    // public func close() {
    //     channel.close()
    // }

    public func connect(host: String, port: Port) -> Promise<()> {
        return Promise { [socketFD, fd, channel = self.channel] resolve, reject in
            var addrInfoPointer: UnsafeMutablePointer<addrinfo>? = nil

            #if os(Linux)
                var hints = addrinfo(
                    ai_flags: 0,
                    ai_family: socketFD.addressFamily.rawValue,
                    ai_socktype: Int32(SOCK_STREAM.rawValue),
                    ai_protocol: 0,
                    ai_addrlen: 0,
                    ai_addr: nil,
                    ai_canonname: nil,
                    ai_next: nil
                )
            #else
                var hints = addrinfo(
                    ai_flags: 0,
                    ai_family: socketFD.addressFamily.rawValue,
                    ai_socktype: SOCK_STREAM,
                    ai_protocol: 0,
                    ai_addrlen: 0,
                    ai_canonname: nil,
                    ai_addr: nil,
                    ai_next: nil
                )
            #endif

            let ret = getaddrinfo(host, String(port), &hints, &addrInfoPointer)
            if let systemError = SystemError(errorNumber: ret) {
                reject(systemError)
                return
            }

            let addressInfo = addrInfoPointer!.pointee
            #if os(Linux)
                let connectRet = Glibc.connect(
                    fd.rawValue,
                    addressInfo.ai_addr,
                    socklen_t(MemoryLayout<sockaddr>.stride)
                )
            #else
                let connectRet = Darwin.connect(
                    fd.rawValue,
                    addressInfo.ai_addr,
                    socklen_t(MemoryLayout<sockaddr>.stride)
                )
            #endif
            freeaddrinfo(addrInfoPointer)

            // Blocking, connect immediately or throw error
            if socketFD.blocking {
                if connectRet != 0 {
                    reject(SystemError(errorNumber: errno)!)
                } else {
                    resolve(())
                }
                return
            }

            // Non-blocking, check for immediate connection
            if connectRet == 0 {
                resolve(())
                return
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
                        reject(systemError)
                        return
                    }
                    if let systemError = SystemError(errorNumber: Int32(result)) {
                        reject(systemError)
                        return
                    }
                    if let systemError = SystemError(errorNumber: error) {
                        reject(systemError)
                        return
                    }
                    resolve(())
                }
            } else if let error = error {
                reject(error)
            }
        }
    }
}
