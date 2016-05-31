//
//  Test.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation

func tcpExample() {
    
    let loop = RunLoop()
    let server = TCPServer(loop: loop)
    
    try! server.bind(host: "0.0.0.0", port: 50000)
    
    server.listen().startWithNext { connection in
        let read = connection.read()
        let strings = read.map { String(bytes: $0, encoding: NSUTF8StringEncoding)! }
        
        strings.onNext { message in
            print("Client \(connection) says \"\(message)\"!")
        }
        
        strings.onFailed { error in
            print("Oh no, there was an error! \(error)")
        }
        
        strings.onCompleted {
            print("Goodbye \(connection)!")
        }
        
        read.start()
    }
    
    RunLoop.runAll()
}