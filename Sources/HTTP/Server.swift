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

    func clientSource(host: String, port: POSIX.Port) -> Source<ClientConnection> {
        return Source { [reuseAddress, reusePort] observer in
            let tcpServer = try! TCP.Server(reuseAddress: reuseAddress, reusePort: reusePort)
            try! tcpServer.bind(host: host, port: port)

            let listen = tcpServer.listen()
            listen.onNext { socket in
                observer.sendNext(ClientConnection(socket: socket))
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
        let source = clientSource(host: host, port: port)
        source.onNext { client in
            let requestStream = client.read()
            let responses = self.delegate.handle(requests: requestStream.signal)
            responses.onNext { response in
                client.write(response).start()
            }
            requestStream.start()
        }
        disposable = ActionDisposable {
            source.stop()
        }
        source.start()
    }

}
