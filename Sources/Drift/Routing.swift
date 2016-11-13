import Foundation
import Reflex
import HTTP
import POSIX
import POSIXExtensions

final class Router: EndpointType {
    
    var endpoints: [EndpointType] = []
    var subpath: String = ""
    weak var parent: Router? = nil
    private var disposable: ActionDisposable? = nil
    
    deinit {
        disposable?.dispose()
    }
    
    var filter: (Signal<Request, ClientError>)
        -> (Signal<Request, ClientError>, Signal<Request, ClientError>) = { requests in
            return (requests, Signal.empty)
    }
    
    func start(host: String, port: POSIXExtensions.Port) {
        let server = HTTP.Server()
        let stream = server.listen(host: host, port: port)
        stream.onNext { [weak self] client in
            let requestStream = client.read()
            if let (responses, unhandledRequests) = self?.process(requests: requestStream.signal) {
                responses.onNext { response in
                    client.write(response).start()
                }
                unhandledRequests.onNext { request in
                    fatalError("Unhandled request: \(request)")
                }
                requestStream.start()
            }
        }
        disposable = ActionDisposable {
            stream.stop()
        }
        stream.start()
    }
    
    var path: String {
        return ((parent?.path ?? "") + subpath).characters.reduce("") { (result, character) in
            if let last = result.characters.last, character == last, last == "/" {
                return result
            } else {
                return result + String(character)
            }
        }
    }
    
    func add(_ subrouter: Router) {
        add("", subrouter)
    }
    
    func add(_ subpath: String = "", _ subrouter: Router) {
        subrouter.parent = self
        subrouter.subpath = subpath
        endpoints.append(subrouter)
    }
    
    func filter(_ subpath: String) -> Router {
        let router = Router()
        add(subpath, router)
        return router
    }
    
    func matches(path: String) -> Bool {
        return zip(
            self.path.components(separatedBy: "/"),
            path.components(separatedBy: "/")
            ).reduce(true) { (result, components) in
                return components.0 == components.1 && result
        }
    }
    
    private func endpoint(_ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self) { requests in
            let (matches, leftover) = requests.partition { request in
                return self.matches(path: request.uri.path)
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(endpoint)
    }
    
    private func endpoint(method: HTTP.Method, _ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self, method: method) { requests in
            let (matches, leftover) = requests.partition { request in
                return self.matches(path: request.uri.path) && request.method == method
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(endpoint)
    }
    
    func get(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .get, transform)
        } else {
            endpoint(method: .get, transform)
        }
    }
    
    func post(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .post, transform)
        } else {
            endpoint(method: .post, transform)
        }
    }
    
    func put(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .put, transform)
        } else {
            endpoint(method: .put, transform)
        }
    }
    
    func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .delete, transform)
        } else {
            endpoint(method: .delete, transform)
        }
    }
    
    func any(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(transform)
        } else {
            endpoint(transform)
        }
    }
    
    func map(_ transform: @escaping (Request) -> Request) -> Self {
        endpoints.append(Endpoint(parent: self) { requests in
            (Signal<Response, ClientError>.empty, requests.map(transform))
        })
        return self
    }
    
    func filter(_ predicate: @escaping (Request) -> Bool) -> Self {
        filter = { requests in
            requests.partition(predicate)
        }
        return self
    }
    
    func process(requests: Signal<Request, ClientError>) -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        var (currentUnhandledRequests, skippedRequests) = filter(requests)
        let (allResponses, allResponsesInput) = Signal<Response, ClientError>.pipe()
        let (allRequests, allRequestsInput) = Signal<Request, ClientError>.pipe()
        for endpoint in endpoints {
            let (responses, unhandledRequests) = endpoint.process(requests: currentUnhandledRequests)
            responses.add(observer: allResponsesInput)
            currentUnhandledRequests = unhandledRequests
        }
        currentUnhandledRequests.add(observer: allRequestsInput)
        skippedRequests.add(observer: allRequestsInput)
        return (allResponses, allRequests)
    }
    
}

extension Router: CustomStringConvertible  {
    
    var description: String {
        return endpoints.map{ $0.description }.joined(separator: "\n")
    }
    
}

struct Endpoint: EndpointType {
    
    let method: HTTP.Method?
    weak var parent: Router?
    
    let transform: (Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>)
    
    init(parent: Router, method: HTTP.Method? = nil, _ transform: @escaping (Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>)) {
        self.transform = transform
        self.parent = parent
        self.method = method
    }

    func process(requests: Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        return transform(requests)
    }
    
    var description: String {
        if let method = method {
            return "\(method) \(path)"
        }
        return "ANY \(path)"
    }

    var path: String {
        return (parent?.path ?? "")
    }
    
}


protocol EndpointType: CustomStringConvertible {
    
    var path: String { get }
    func process(requests: Signal<Request, ClientError>) -> (Signal<Response, ClientError>, Signal<Request, ClientError>)
    
}

