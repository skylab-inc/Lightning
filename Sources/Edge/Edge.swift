//
//  Edge.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/5/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif
import Dispatch

public struct Edge {

    private init() {}

    public static func run(ignoreSigPipe: Bool = true) {
        if ignoreSigPipe {
            #if os(Linux)
                Glibc.signal(SIGPIPE, SIG_IGN)
            #else
                Darwin.signal(SIGPIPE, SIG_IGN)
            #endif
        }
        dispatchMain()
    }

}
