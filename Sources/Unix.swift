//
//  Unix.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Foundation

public struct SocketType {
    static let stream = SocketType(rawValue: SOCK_STREAM)
    static let datagram = SocketType(rawValue: SOCK_DGRAM)
    static let seqPacket = SocketType(rawValue: SOCK_SEQPACKET)
    static let raw = SocketType(rawValue: SOCK_RAW)
    static let reliableDatagram = SocketType(rawValue: SOCK_RDM)
    
    let rawValue: Int32
    
    init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct AddressFamily {
    static let unix = AddressFamily(rawValue: AF_UNIX)
    static let inet = AddressFamily(rawValue: AF_INET)
    static let inet6 = AddressFamily(rawValue: AF_INET6)
    static let ipx = AddressFamily(rawValue: AF_IPX)
    static let netlink = AddressFamily(rawValue: AF_APPLETALK)
    
    let rawValue: Int32
    
    init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public typealias Port = UInt16

public protocol FileDescriptor {
    
    var rawValue: Int32 { get }
    
}

public enum StandardFileDescriptor: Int32, FileDescriptor {
    case invalid = -1
    case stdin = 0
    case stdout = 1
    case stderr = 2
}

public struct SocketFileDescriptor: CustomDebugStringConvertible, FileDescriptor {
    public let rawValue: Int32
    let addressFamily: AddressFamily
    let socketType: SocketType
    let blocking: Bool
    
    init(socketType: SocketType, addressFamily: AddressFamily, blocking: Bool = false) {
        self.rawValue = socket(addressFamily.rawValue, socketType.rawValue, 0)
        if !blocking {
            let flags = fcntl(self.rawValue, F_GETFL, 0);
            _ = fcntl(self.rawValue, F_SETFL, flags | O_NONBLOCK)
        }
        self.addressFamily = addressFamily
        self.socketType = socketType
        self.blocking = blocking
    }
    
    init(rawValue: Int32, socketType: SocketType, addressFamily: AddressFamily, blocking: Bool) {
        self.rawValue = rawValue
        self.addressFamily = addressFamily
        self.socketType = socketType
        self.blocking = blocking
    }
    
    public var debugDescription: String {
        return "\(String(rawValue))"
    }
}

public enum Error: ErrorProtocol {
    case access
    case addressInUse
    case invalidFileDesciptor
    case invalidAddress
    case tryAgain
    case notASocket
    case addressNotAvailable
    case invalidMemory
    case tooManySymLinks
    case nameTooLong
    case pathDoesNotExist
    case noMemory
    case readOnlyFileSystem
    case connectionRefused
    case interrupt
    case invalidArgument
    case notConnected
    case notValidExecutable
    case operationNotSupported
    case inProgress
    case unknownError
    
    public init(rawValue: Int32) {
        switch rawValue {
        case EACCES:
            self = access
        case EADDRINUSE:
            self = addressInUse
        case EBADF:
            self = invalidFileDesciptor
        case EINVAL:
            self = invalidAddress
        case EAGAIN:
            self = tryAgain
        case ENOTSOCK:
            self = notASocket
        case EADDRNOTAVAIL:
            self = addressNotAvailable
        case EFAULT:
            self = invalidMemory
        case ELOOP:
            self = tooManySymLinks
        case ENAMETOOLONG:
            self = nameTooLong
        case ENOENT:
            self = pathDoesNotExist
        case ENOMEM:
            self = noMemory
        case EROFS:
            self = readOnlyFileSystem
        case ECONNREFUSED:
            self = connectionRefused
        case EINTR:
            self = interrupt
        case EINVAL:
            self = invalidArgument
        case ENOTCONN:
            self = notConnected
        case ENOEXEC:
            self = notValidExecutable
        case EOPNOTSUPP:
            self = operationNotSupported
        case EINPROGRESS:
            self = inProgress
        default:
            self = unknownError
        }
    }
    
}

public enum AddressFamilyError: ErrorProtocol {
    case tryAgain
    case badFlags
    case fail
    case family
    case memory
    case noName
    case overflow
    case system
    case unknownError
    
    init(rawValue: Int32) {
        switch rawValue {
        case EAI_AGAIN:
            self = tryAgain
        case EAI_BADFLAGS:
            self = badFlags
        case EAI_FAIL:
            self = fail
        case EAI_FAMILY:
            self = family
        case EAI_MEMORY:
            self = memory
        case EAI_NONAME:
            self = noName
        case EAI_OVERFLOW:
            self = overflow
        case EAI_SYSTEM:
            self = system
        default:
            self = unknownError
        }
    }
}
