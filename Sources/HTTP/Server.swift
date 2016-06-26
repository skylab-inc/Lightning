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
    
    public let parser: RequestParser
    
    init() {
        self.parser = RequestParser()
    }
    
    public func listen(host: String, port: Port) -> ColdSignal<Request, SystemError> {
        return ColdSignal { observer in
            
            let tcpServer = try! TCP.Server()
            try! tcpServer.bind(host: host, port: port)
            
            let listen = tcpServer.listen()
            listen.onNext { connection in
                /*
                let read = connection.read()
                read.onNext { data in
                    if let request = try! self.parser.parse(Data(data)) {
                        let response = try! middleware.chain(to: responder).respond(to: request)
                        try! serializer.serialize(response, to: stream)

                        if let upgrade = response.didUpgrade {
                            try! upgrade(request, stream)
                            try! stream.close()
                        }

                        if !request.isKeepAlive {
                            try! stream.close()
                        }
                    }
                    
                }
                read.start()
                */
            }
            listen.start()

            return ActionDisposable {
                listen.stop()
            }
        }

    }

}
