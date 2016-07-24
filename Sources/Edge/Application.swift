//
//  Application.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 7/1/16.
//
//

import Foundation
import POSIX
import POSIXExtensions
import Reflex
import HTTP
import S4

public final class Application {
    
    var subApps = [Application]()
    let server = HTTP.Server()
    var clientSignals = [Signal<HTTP.Request, S4.ClientError>]()
    
    init() {
        
    }
    
    public func listen(host: String = "0.0.0.0", port: POSIXExtensions.Port) {
        
//        let (signal, observer) = Signal<Signal<HTTP.Request, S4.ClientError>, S4.ClientError>.pipe()
        server.listen(host: host, port: port).startWithNext { client in
//            let mapped = client.read().checkAuth()
//                .map { request in
//                
//                }
//                .filter { request in
//                    
//                }
//                .reduce {
//                    
//                }
            let requestSignal = client.read()
            self.clientSignals.append(requestSignal.map{ $0 })
            requestSignal.start()
        }
    }
    
    public func get(_ path: String, _ map: (HTTP.Request) -> HTTP.Response) {
        for signal in self.clientSignals {
            signal.filter { request in
                request.method == .get && path == request.uri.path
            }.map(transform: map).onNext { response in
                
            }
        }
    }
    
//    public func get(_ path: String) -> Signal<HTTP.Request, S4.ClientError> {
//        return Signal { observer in
//            for signal in self.clientSignals {
//                signal.filter { request in
//                    request.method == .get && path == request.uri.path
//                }.onNext(next: observer.sendNext)
//            }
//            return nil
//        }
//    }
    
}
