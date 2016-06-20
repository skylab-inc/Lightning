#if os(Linux)
import Glibc
#else
import Darwin
#endif

import POSIX

public protocol FileDescriptor {
    
    var rawValue: Int32 { get }
    
    func close()
    
}

extension FileDescriptor {
    
    public func close() {
        _ = systemClose(rawValue)
    }
}

public enum StandardFileDescriptor: Int32, FileDescriptor {
    case invalid = -1
    case stdin = 0
    case stdout = 1
    case stderr = 2
}

public struct SocketFileDescriptor: CustomDebugStringConvertible, FileDescriptor {
    
    public let rawValue: Int32
    public let addressFamily: AddressFamily
    public let socketType: SocketType
    public let blocking: Bool
    
    public init(socketType: SocketType, addressFamily: AddressFamily, blocking: Bool = false) throws {
        self.rawValue = socket(addressFamily.rawValue, socketType.rawValue, 0)
        if self.rawValue == StandardFileDescriptor.invalid.rawValue {
            throw SystemError(errorNumber: errno)!
        }

        if !blocking {
            let flags = fcntl(self.rawValue, F_GETFL, 0);
            let error = fcntl(self.rawValue, F_SETFL, flags | O_NONBLOCK)
            if error == -1 {
                throw SystemError(errorNumber: errno)!
            }
        }

        self.addressFamily = addressFamily
        self.socketType = socketType
        self.blocking = blocking
    }
    
    public init(rawValue: Int32, socketType: SocketType, addressFamily: AddressFamily, blocking: Bool) {
        self.rawValue = rawValue
        self.addressFamily = addressFamily
        self.socketType = socketType
        self.blocking = blocking
    }
    
    public var debugDescription: String {
        return "\(String(rawValue))"
    }
}
