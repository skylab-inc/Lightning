//
//  Server.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 4/30/16.
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

public final class Server {

    public static let defaultReuseAddress = false
    public static let defaultReusePort = false

    private let fd: SocketFileDescriptor
    private let listeningSource: DispatchSourceRead

    public convenience init(reuseAddress: Bool = defaultReuseAddress, reusePort: Bool = defaultReusePort) throws {
        let fd = try SocketFileDescriptor(
            socketType: SocketType.stream,
            addressFamily: AddressFamily.inet
        )
        try self.init(fd: fd, reuseAddress: reuseAddress, reusePort: reusePort)
    }

    public init(fd: SocketFileDescriptor, reuseAddress: Bool = defaultReuseAddress, reusePort: Bool = defaultReusePort) throws {
        self.fd = fd
        if reuseAddress {
            // Set SO_REUSEADDR
            var reuseAddr = 1
            let error = setsockopt(
                self.fd.rawValue,
                SOL_SOCKET,
                SO_REUSEADDR,
                &reuseAddr,
                socklen_t(MemoryLayout<Int>.stride)
            )
            if error != 0 {
                throw SystemError(errorNumber: errno)!
            }
        }

        if reusePort {
            // Set SO_REUSEPORT
            var reusePort = 1
            let error = setsockopt(
                self.fd.rawValue,
                SOL_SOCKET,
                SO_REUSEPORT,
                &reusePort,
                socklen_t(MemoryLayout<Int>.stride)
            )
            if let systemError = SystemError(errorNumber: error) {
                throw systemError
            }
        }

        self.listeningSource = DispatchSource.makeReadSource(
            fileDescriptor: self.fd.rawValue,
            queue: .main
        )
    }

    public func bind(host: String, port: Port) throws {
        var addrInfoPointer: UnsafeMutablePointer<addrinfo>? = nil

        #if os(Linux)
            var hints = Glibc.addrinfo(
                ai_flags: 0,
                ai_family: fd.addressFamily.rawValue,
                ai_socktype: Int32(SOCK_STREAM.rawValue),
                ai_protocol: Int32(IPPROTO_TCP),
                ai_addrlen: 0,
                ai_addr: nil,
                ai_canonname: nil,
                ai_next: nil
            )
        #else
            var hints = Darwin.addrinfo(
                ai_flags: 0,
                ai_family: fd.addressFamily.rawValue,
                ai_socktype: SOCK_STREAM,
                ai_protocol: IPPROTO_TCP,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
        #endif

        let ret = getaddrinfo(host, String(port), &hints, &addrInfoPointer)
        if let systemError = SystemError(errorNumber: ret) {
            throw systemError
        }

        let addressInfo = addrInfoPointer!.pointee

        #if os(Linux)
            let bindRet = Glibc.bind(
                fd.rawValue,
                addressInfo.ai_addr,
                socklen_t(MemoryLayout<sockaddr>.stride)
            )
        #else
             let bindRet = Darwin.bind(
                fd.rawValue,
                addressInfo.ai_addr,
                socklen_t(MemoryLayout<sockaddr>.stride)
            )
        #endif
        freeaddrinfo(addrInfoPointer)

        if bindRet != 0 {
            throw SystemError(errorNumber: errno)!
        }
    }

    public func listen(backlog: Int = 32) -> Source<Socket> {
        return Source { [listeningSource = self.listeningSource, fd = self.fd] observer in
            #if os(Linux)
                let ret = Glibc.listen(fd.rawValue, Int32(backlog))
            #else
                let ret = Darwin.listen(fd.rawValue, Int32(backlog))
            #endif
            if ret != 0 {
                observer.sendFailed(SystemError(errorNumber: errno)!)
                return nil
            }
            listeningSource.setEventHandler {

                var socketAddress = sockaddr()
                var sockLen = socklen_t(MemoryLayout<sockaddr>.size)

                // Accept connections
                let numPendingConnections: UInt = listeningSource.data
                for _ in 0..<numPendingConnections {
                    #if os(Linux)
                        let ret = Glibc.accept(fd.rawValue, &socketAddress, &sockLen)
                    #else
                        let ret = Darwin.accept(fd.rawValue, &socketAddress, &sockLen)
                    #endif
                    if ret == StandardFileDescriptor.invalid.rawValue {
                        observer.sendFailed(SystemError(errorNumber: errno)!)
                    }
                    let clientFileDescriptor = SocketFileDescriptor(
                        rawValue: ret,
                        socketType: SocketType.stream,
                        addressFamily: fd.addressFamily,
                        blocking: false
                    )

                    do {
                        // Create the client connection socket
                        let clientConnection = try Socket(fd: clientFileDescriptor)
                        observer.sendNext(clientConnection)
                    } catch let systemError as SystemError {
                        observer.sendFailed(systemError)
                        return
                    } catch {
                        fatalError("Unexpected error ")
                    }
                }
            }
            // Close the socket when the source is canceled.
            listeningSource.setCancelHandler {
                fd.close()
            }
            if #available(OSX 10.12, *) {
                listeningSource.activate()
            } else {
                listeningSource.resume()
            }
            return ActionDisposable {
                listeningSource.cancel()
            }
        }
    }
}
