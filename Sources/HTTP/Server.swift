//
//  HTTP.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 6/22/16.
//
//

import Dispatch
import StreamKit
import POSIX
import Foundation
import TCP

public protocol ServerDelegate {

    func handle(requests: Signal<Request>) -> Signal<Response>

}

public final class Server {

    let delegate: ServerDelegate
    private var disposable: ActionDisposable? = nil
    let reuseAddress: Bool
    let reusePort: Bool

    public init(delegate: ServerDelegate? = nil, reuseAddress: Bool = false, reusePort: Bool = false) {
        self.delegate = delegate ?? Router()
        self.reuseAddress = reuseAddress
        self.reusePort = reusePort
    }

    deinit {
        self.stop()
    }

    public func stop() {
        disposable?.dispose()
    }

    public func parse(data dataStream: Source<Data>) -> Source<Request> {
        return Source { observer in
            let parser = RequestParser()
            parser.onRequest = { request in
                observer.sendNext(request)
            }
            dataStream.onNext { data in
                do {
                    try parser.parse(data)
                } catch {
                    // Respond with 400 error
                    observer.sendFailed(ClientError.badRequest)
                }
            }
            dataStream.onCompleted {
                observer.sendCompleted()
            }
            dataStream.onFailed { error in
                observer.sendFailed(error)
            }
            dataStream.start()
            return ActionDisposable {
                dataStream.stop()
            }
        }

    }

    public func serialize(responses: Signal<Response>) -> Signal<Data> {
        return responses.map { $0.serialized }
    }

    func clients(host: String, port: POSIX.Port) -> Source<Socket> {
        return Source { [reuseAddress, reusePort] observer in
            let tcpServer = try! TCP.Server(reuseAddress: reuseAddress, reusePort: reusePort)
            try! tcpServer.bind(host: host, port: port)

            let listen = tcpServer.listen()
            listen.onNext { socket in
                observer.sendNext(socket)
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

    public func listen(host: String, port: POSIX.Port) {
        let clients = self.clients(host: host, port: port)
        var connectedClients: [Socket] = []
        clients.onNext { socket in
            connectedClients.append(socket)
            let requestStream = self.parse(data: socket.read())
            let responses = self.delegate.handle(requests: requestStream.signal)
            let data = self.serialize(responses: responses)
            _ = socket.write(stream: data)
            requestStream.start()
        }
        disposable = ActionDisposable {
            clients.stop()
            for socket in connectedClients {
                socket.close()
            }
        }
        clients.start()
    }

}
