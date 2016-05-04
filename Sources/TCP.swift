//
//  TCP.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 4/30/16.
//
//

#if os(Linux)
    import Glibc
    private let system_bind = Glibc.bind
    private let system_accept = Glibc.accept
    private let system_listen = Glibc.listen
    private let system_connect = Glibc.connect
#else
    import Darwin
    private let system_bind = Darwin.bind
    private let system_accept = Darwin.accept
    private let system_listen = Darwin.listen
    private let system_connect = Darwin.connect
#endif
import Dispatch

public struct TCPClient: IOStream {
    
    public let loop: RunLoop
    private let socketFD: SocketFileDescriptor
    public var fd: FileDescriptor {
        return socketFD
    }
    public let channel: dispatch_io_t

    let connectingSource: dispatch_source_t
    
    public init(loop: RunLoop) {
        self.init(loop: loop, fd: SocketFileDescriptor(socketType: SocketType.stream, addressFamily: AddressFamily.inet))
    }
    
    public init(loop: RunLoop, fd: SocketFileDescriptor) {
        self.loop = loop
        self.socketFD = fd
        self.connectingSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(fd.rawValue), 0, dispatch_get_main_queue())
        self.channel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                print("Error: \(error)")
            }
        }
    }
    
    public func connect(host: String, port: Port, onConnect: () -> ()) throws {
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
        let connectRet = system_connect(fd.rawValue, addressInfo.ai_addr, socklen_t(sizeof(sockaddr)))
        freeaddrinfo(addrInfoPointer)
        
        // Blocking, connect immediately or throw error
        if socketFD.blocking {
            if connectRet != 0 {
                throw Error(rawValue: errno)
            }
            onConnect()
            return
        }
        
        // Non-blocking, check for immediate connection
        if connectRet == 0 {
            onConnect()
            return
        }
        
        // Non-blocking, dispatch connection
        if Error(rawValue: connectRet) == Error.inProgress {
            dispatch_source_set_event_handler(connectingSource) {
                var result = 0
                var resultLength = socklen_t(strideof(result.dynamicType))
                let ret = getsockopt(self.fd.rawValue, SOL_SOCKET, SO_ERROR, &result, &resultLength)
                if ret != 0 {
                    try! { throw Error(rawValue: ret) }()
                }
                if result != 0 {
                    try! { throw Error(rawValue: ret) }()
                }
                onConnect()
            }
            dispatch_resume(connectingSource)
        }
    }
}

public struct TCPServer: IOStream {
    
    public let loop: RunLoop
    private let socketFD: SocketFileDescriptor
    public var fd: FileDescriptor {
        return socketFD
    }
    let listeningSource: dispatch_source_t
    public let channel: dispatch_io_t
    
    public init(loop: RunLoop) {
        self.init(loop: loop, fd: SocketFileDescriptor(socketType: SocketType.stream, addressFamily: AddressFamily.inet))
    }
    
    public init(loop: RunLoop, fd: SocketFileDescriptor) {
        self.loop = loop
        self.socketFD = fd
        self.listeningSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(fd.rawValue), 0, dispatch_get_main_queue())
        self.channel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                print("Error: \(error)")
            }
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
    
    public func listen(backlog: Int = 32, onConnect: (clientConnection: TCPServer) -> ()) throws {
        let ret = system_listen(fd.rawValue, Int32(backlog))
        if ret != 0 {
            throw Error(rawValue: errno)
        }
        debugPrint("Listening on \(fd)...")
        dispatch_source_set_event_handler(listeningSource) { [fd = self.fd] in
            debugPrint("Connecting...")
            var socketAddress = sockaddr()
            var sockLen = socklen_t(SOCK_MAXADDRLEN)
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
            let clientConnection = TCPServer(loop: self.loop, fd: clientFileDescriptor)
            onConnect(clientConnection: clientConnection)
        }
        dispatch_resume(listeningSource)
    }
}
