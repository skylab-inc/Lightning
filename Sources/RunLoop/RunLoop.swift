//
//  RunLoop.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/2/16.
//
//

import Dispatch
#if os(Linux)
    import Glibc
    public let systemSignal = Glibc.signal
    public let SIGPIPE = Glibc.SIGPIPE
    public let SIG_IGN = Glibc.SIG_IGN
#else
    import Darwin
    public let systemSignal = Darwin.signal
    public let SIGPIPE = Darwin.SIGPIPE
    public let SIG_IGN = Darwin.SIG_IGN
#endif

public struct RunLoop {
    
    public init() {
        
    }
    
    public static func runAll(ignoreSigPipe: Bool = true) {
        if ignoreSigPipe {
            signal(SIGPIPE, SIG_IGN)
        }
        dispatchMain()
    }
    
}
