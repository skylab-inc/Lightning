//
//  Test.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/29/16.
//
//

import Foundation


func main() {
    
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
    
    
//    listen.observeNext { connection in
//        
//        let read = connection.read()
//        read.observeNext { buffer in
//            
//        }
//        read.start()
//        
//    }
//    
//    server.listen().on
//    server.listen().onNext { socket in
//        <#code#>
//    }
    
//    server.listen().subscribeNext { connection in
//        
//        _ = MessageStream(socket: connection).subscribe(
//            onNext: { message in
//                
//                switch message.header.type {
//                case .coordUpdate:
//                    let update = CoordUpdate(buffer: message.payload)
//                    world.setStoredLandType(for: update.coord, landType: update.landType)
//                    log.debug(world.storedLandTypes)
//                case .longTestMessage:
//                    let ltm = LongTestMessage(buffer: message.payload)
//                }
//                
//                let echoBuffer = message.header.messageBuffer + message.payload
//                _ = connection.write(buffer: echoBuffer).subscribe()
//                
//            },
//            onError: { error in
//                //            log.error("\(error)")
//            },
//            onCompleted: {
//                //            log.debug("Connection ended by client.")
//            }
//        )
//    }
    
    RunLoop.runAll()
    
}