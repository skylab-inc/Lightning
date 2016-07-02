//
//  HTTP.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/22/16.
//
//

import Dispatch
import Reactive
import POSIX
import POSIXExtensions
import TCP

public final class Server {
    
    private var observer: Observer<Request, SystemError>! = nil
    
    public func listen(host: String, port: Port) -> ColdSignal<Request, SystemError> {
        return ColdSignal { observer in
            self.observer = observer
            
            let tcpServer = try! TCP.Server()
            try! tcpServer.bind(host: host, port: port)
            
            let listen = tcpServer.listen()
            listen.onNext { connection in
                
                // Create parser for connection/
                let parser = RequestParser { request in
                    self.observer.sendNext(request)
                }
                
                // Read from connection and parse data.
                let read = connection.read()
                read.onNext { data in
                    try! parser.parse(data)
                }
                read.start()
            }
            listen.onFailed { error in
                observer.sendFailed(error)
            }
            listen.start()

            return ActionDisposable {
                listen.stop()
            }
        }

    }

}
