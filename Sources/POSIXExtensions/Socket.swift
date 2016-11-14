// swiftlint:disable variable_name
// swiftlint:disable function_parameter_count
#if os(Linux)
    import Glibc
    public let systemBind = Glibc.bind
    public let systemAccept = Glibc.accept
    public let systemListen = Glibc.listen
    public let systemConnect = Glibc.connect
    public let systemClose = Glibc.close

    public let SOCK_STREAM = Int32(Glibc.SOCK_STREAM.rawValue)
    public let SOCK_DGRAM = Int32(Glibc.SOCK_DGRAM.rawValue)
    public let SOCK_SEQPACKET = Int32(Glibc.SOCK_SEQPACKET.rawValue)
    public let SOCK_RAW = Int32(Glibc.SOCK_RAW.rawValue)
    public let SOCK_RDM = Int32(Glibc.SOCK_RDM.rawValue)

    public let SOCK_MAXADDRLEN: Int32 = 255
    public let IPPROTO_TCP = Int32(Glibc.IPPROTO_TCP)

    public func systemCreateAddressInfo(
        ai_flags: Int32,
        ai_family: Int32,
        ai_socktype: Int32,
        ai_protocol: Int32,
        ai_addrlen: socklen_t,
        ai_canonname: UnsafeMutablePointer<Int8>!,
        ai_addr: UnsafeMutablePointer<sockaddr>!,
        ai_next: UnsafeMutablePointer<addrinfo>!
        ) -> addrinfo {
        return addrinfo(
            ai_flags: ai_flags,
            ai_family: ai_family,
            ai_socktype: ai_socktype,
            ai_protocol: ai_protocol,
            ai_addrlen: ai_addrlen,
            ai_addr: ai_addr,
            ai_canonname: ai_canonname,
            ai_next: ai_next
        )
    }
#else
    import Darwin
    public let systemBind = Darwin.bind
    public let systemAccept = Darwin.accept
    public let systemListen = Darwin.listen
    public let systemConnect = Darwin.connect
    public let systemClose = Darwin.close

    public let SOCK_STREAM = Darwin.SOCK_STREAM
    public let SOCK_DGRAM = Darwin.SOCK_DGRAM
    public let SOCK_SEQPACKET = Darwin.SOCK_SEQPACKET
    public let SOCK_RAW = Darwin.SOCK_RAW
    public let SOCK_RDM = Darwin.SOCK_RDM

    public let IPPROTO_TCP = Darwin.IPPROTO_TCP
    public let SOCK_MAXADDRLEN = Darwin.SOCK_MAXADDRLEN

    public func systemCreateAddressInfo(
        ai_flags: Int32,
        ai_family: Int32,
        ai_socktype: Int32,
        ai_protocol: Int32,
        ai_addrlen: socklen_t,
        ai_canonname: UnsafeMutablePointer<Int8>!,
        ai_addr: UnsafeMutablePointer<sockaddr>!,
        ai_next: UnsafeMutablePointer<addrinfo>!
        ) -> addrinfo {
        return addrinfo(
            ai_flags: ai_flags,
            ai_family: ai_family,
            ai_socktype: ai_socktype,
            ai_protocol: ai_protocol,
            ai_addrlen: ai_addrlen,
            ai_canonname: ai_canonname,
            ai_addr: ai_addr,
            ai_next: ai_next
        )
    }
#endif
// swiftlint:enable function_parameter_count
// swiftlint:enable variable_name

public struct SocketType {

    public static let stream = SocketType(rawValue: SOCK_STREAM)
    public static let datagram = SocketType(rawValue: SOCK_DGRAM)
    public static let seqPacket = SocketType(rawValue: SOCK_SEQPACKET)
    public static let raw = SocketType(rawValue: SOCK_RAW)
    public static let reliableDatagram = SocketType(rawValue: SOCK_RDM)

    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct AddressFamily {
    public static let unix = AddressFamily(rawValue: AF_UNIX)
    public static let inet = AddressFamily(rawValue: AF_INET)
    public static let inet6 = AddressFamily(rawValue: AF_INET6)
    public static let ipx = AddressFamily(rawValue: AF_IPX)
    public static let netlink = AddressFamily(rawValue: AF_APPLETALK)

    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public typealias Port = UInt16
