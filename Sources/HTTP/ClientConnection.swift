//
//  ClientConnection.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 7/9/16.
//
//

import Foundation
import TCP
import Reflex

public final class ClientConnection {
    
    let socket: TCP.Socket
    var parser = RequestParser()
    
    init(socket: TCP.Socket) {
        self.socket = socket
    }
    
    public func read() -> ColdSignal<Request, ClientError> {
        return ColdSignal { observer in
            let read = self.socket.read()
            self.parser.onRequest = { request in
                observer.sendNext(request)
            }
            
            read.onNext { data in
                do {
                    try self.parser.parse(data)
                } catch {
                    // Respond with 400 error
                    observer.sendFailed(.badRequest)
                }
            }
            read.start()
            
            return ActionDisposable {
                read.stop()
            }
        }
    }
    
    public func write(_ response: Response) {
        socket.write(buffer: response.serialized).start()
    }

}
