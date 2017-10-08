import libc
#if os(Linux)
    @_exported import Glibc
    let sockStream = Int32(SOCK_STREAM.rawValue)
    let sockDgram = Int32(SOCK_DGRAM.rawValue)
    let sockSeqPacket = Int32(SOCK_SEQPACKET.rawValue)
    let sockRaw = Int32(SOCK_RAW.rawValue)
    let sockRDM = Int32(SOCK_RDM.rawValue)
#else
    @_exported import Darwin.C
    let sockStream = SOCK_STREAM
    let sockDgram = SOCK_DGRAM
    let sockSeqPacket = SOCK_SEQPACKET
    let sockRaw = SOCK_RAW
    let sockRDM = SOCK_RDM
#endif

public typealias Port = UInt16

public struct SocketType {

    public static let stream = SocketType(rawValue: sockStream)
    public static let datagram = SocketType(rawValue: sockDgram)
    public static let seqPacket = SocketType(rawValue: sockSeqPacket)
    public static let raw = SocketType(rawValue: sockRaw)
    public static let reliableDatagram = SocketType(rawValue: sockRDM)

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
