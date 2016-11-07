import Foundation
import Edge
import Reflex
import POSIX
import POSIXExtensions

class App: RouterType {
    
    let requests: Signal<Request, SystemError>
    let requestsInput: Observer<Request, SystemError>
    
    let responses: Signal<Response, SystemError>
    let responsesOutput: Observer<Response, SystemError>
    
    let path: String
    weak var parent: RouterType? = nil
    
    private let stream: ColdSignal<ClientConnection, SystemError>
    
    init(host: String, port: POSIXExtensions.Port) {
        path = ""
        (requests, requestsInput) = Signal<Request, SystemError>.pipe()
        (responses, responsesOutput) = Signal<Response, SystemError>.pipe()
        
        let server = HTTP.Server()
        stream = server.listen(host: host, port: port)
        stream.onNext { connection in
            connection.read().startWithNext { request in
                self.requestsInput.sendNext(request)
            }
            
            self.responses.onNext { response in
                connection.write(response).start()
            }
        }
    }
    
    func start() {
        print("STAAARRT")
        stream.start()
    }
    
    func stop() {
        stream.stop()
    }
    
    deinit {
        stop()
    }

}

class Router: RouterType {
    
    let requests: Signal<Request, SystemError>
    let requestsInput: Observer<Request, SystemError>

    let responses: Signal<Response, SystemError>
    let responsesOutput: Observer<Response, SystemError>
    
    let path: String
    weak var parent: RouterType? = nil

    init(path: String = "/", requests: Signal<Request, SystemError>? = nil) {
        let (signal, observer) = Signal<Request, SystemError>.pipe()
        self.requests = signal
        self.requestsInput = observer
        
        let (outputSignal, outputObserver) = Signal<Response, SystemError>.pipe()
        self.responses = outputSignal
        self.responsesOutput = outputObserver
        
        self.path = path
    }
    
}

protocol RouterType: class {
    
    var requests: Signal<Request, SystemError> { get }
    var requestsInput: Observer<Request, SystemError> { get }
    
    var responses: Signal<Response, SystemError> { get }
    var responsesOutput: Observer<Response, SystemError> { get }
    
    var path: String { get }
    weak var parent: RouterType? { get set }
    
}

extension RouterType {
    
    var fullPath: String {
        return parent?.fullPath ?? "" + path
    }
    
    private func endpoint(_ transform: @escaping (Request) -> Response) {
        requests
            .filter(matchesPath)
            .map(transform)
            .add(observer: responsesOutput)
    }
    
    private func endpoint(method: HTTP.Method, _ transform: @escaping (Request) -> Response) {
        requests
            .filter(matchesPath)
            .filter { $0.method == method }
            .map(transform)
            .add(observer: responsesOutput)
        
    }
    
    private func endpoint(_ subpath: String, method: HTTP.Method, _ transform: @escaping (Request) -> Response) {
        filter(subpath).endpoint(method: method, transform)
    }
    
    func add(_ subrouter: RouterType) {
        subrouter.parent = self
        requests.filter(matchesPath).add(observer: subrouter.requestsInput)
        subrouter.responses.add(observer: responsesOutput)
    }
    
    func add(_ subpath: String, _ subrouter: RouterType) {
        add(subrouter.filter(subpath))
    }
    
    func matchesPath(request: Request) -> Bool {
        return request.uri.path.hasPrefix(fullPath)
    }
    
    func filter(_ subpath: String) -> RouterType {
        let subrouter = Router(path: subpath)
        self.add(subrouter)
        return subrouter
    }
    
    func get(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(method: .get, transform)
    }
    
    func post(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(method: .post, transform)
    }
    
    func put(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(method: .put, transform)
    }
    
    func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(method: .delete, transform)
    }
    
    func any(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(transform)
    }
    
    func map(_ transform: @escaping (Request) -> Request) -> RouterType {
        let mapped = Router()
        requests.map(transform).add(observer: mapped.requestsInput)
        mapped.responses.add(observer: responsesOutput)
        return mapped
    }
    
    func filter(_ predicate: @escaping (Request) -> Bool) -> RouterType {
        let filtered = Router()
        requests.filter(predicate).add(observer: filtered.requestsInput)
        filtered.responses.add(observer: responsesOutput)
        return filtered
    }
    
}
