//
//  TCPServer.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 4/30/16.
//
//

import Dispatch

public class TCPServer: IOStream {
    
    public let loop: RunLoop
    private let socketFD: SocketFileDescriptor
    public var fd: FileDescriptor {
        return socketFD
    }
    let listeningSource: dispatch_source_t
    public let channel: dispatch_io_t
    
    public var readListeners: [(result: [UInt8]) -> ()] = []
    
    public var writeListeners: [(unwrittenData: [UInt8]?) -> ()] = []
    
    public var closeListeners: [(error: Error?) -> ()] = []
    
    public var writingCompleteListeners: [(error: Error?) -> ()] = []
    
    public convenience init(loop: RunLoop) {
        self.init(loop: loop, fd: SocketFileDescriptor(socketType: SocketType.stream, addressFamily: AddressFamily.inet))
    }
    
    public init(loop: RunLoop, fd: SocketFileDescriptor) {
        self.loop = loop
        self.socketFD = fd
        self.listeningSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(fd.rawValue), 0, dispatch_get_main_queue())
        self.channel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                try! { throw Error(rawValue: error) }()
            }
        }
        
        // Set SO_REUSEADDR
        var reuseAddr = 1
        let error = setsockopt(self.fd.rawValue, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(strideof(Int)))
        if error != 0 {
            try! { throw Error(rawValue: error) }()
        }
    }
    
    public func bind(host: String, port: Port) throws {
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
            throw AddressFamilyError(rawValue: ret)
        }
        
        let addressInfo = addrInfoPointer!.pointee
        
        let bindRet = system_bind(fd.rawValue, addressInfo.ai_addr, socklen_t(sizeof(sockaddr)))
        freeaddrinfo(addrInfoPointer)
        
        if bindRet != 0 {
            throw Error(rawValue: errno)
        }
    }
    
    public func listen(backlog: Int = 32, onConnect: (clientConnection: TCPSocket) -> ()) throws {
        let ret = system_listen(fd.rawValue, Int32(backlog))
        if ret != 0 {
            throw Error(rawValue: errno)
        }
        log.debug("Listening on \(fd)...")
        dispatch_source_set_event_handler(listeningSource) { [fd = self.fd, listeningSource = self.listeningSource] in
            
            log.debug("Connecting...")
            
            var socketAddress = sockaddr()
            var sockLen = socklen_t(SOCK_MAXADDRLEN)
            
            // Accept connections
            let numPendingConnections = dispatch_source_get_data(listeningSource)
            for _ in 0..<numPendingConnections {
                let ret = system_accept(fd.rawValue, &socketAddress, &sockLen)
                if ret == StandardFileDescriptor.invalid.rawValue {
                    try! { throw Error(rawValue: ret) }()
                }
                let clientFileDescriptor = SocketFileDescriptor(
                    rawValue: ret,
                    socketType: SocketType.stream,
                    addressFamily: self.socketFD.addressFamily,
                    blocking: false
                )
                
                // Create the client connection socket and start reading
                let clientConnection = TCPSocket(loop: self.loop, fd: clientFileDescriptor)
                onConnect(clientConnection: clientConnection)
            }
        }
        dispatch_source_set_cancel_handler(listeningSource) {
            // Close the socket
            self.fd.close()
        }
        dispatch_resume(listeningSource)
    }
}
