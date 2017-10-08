import Foundation
import Reflex
import HTTP
import POSIX

public final class Router {

    var endpoints: [RequestTransformer] = []
    var subpath: String = ""
    weak var parent: Router? = nil
    private var disposable: ActionDisposable? = nil

    public init() {

    }

    private init(transformers: [RequestTransformer]) {
        self.endpoints = transformers
    }

    deinit {
        disposable?.dispose()
    }

    func start(host: String, port: POSIX.Port) {
        let server = HTTP.Server()
        let stream = server.listen(host: host, port: port)
        stream.onNext { [weak self] client in
            let requestStream = client.read()
            if let (responses, unhandledRequests) =
                self?.transform(requests: requestStream.signal) {

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

    func matches(path: String) -> Bool {
        return zip(
            self.path.components(separatedBy: "/"),
            path.components(separatedBy: "/")
            ).reduce(true) { (result, components) in
                return components.0 == components.1 && result
        }
    }

    private func endpoint(_ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint { [weak self] requests in
            let (matches, leftover) = requests.partition { [weak self] request in
                return self?.matches(path: request.uri.path) ?? false
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(.endpoint(endpoint))
    }

    private func endpoint(method: HTTP.Method, _ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self, method: method) { [weak self] requests in
            let (matches, leftover) = requests.partition { [weak self] request in
                return self?.matches(path: request.uri.path) ?? false && request.method == method
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(.endpoint(endpoint))
    }

    private func endpoint(
        subpath: String?,
        method: HTTP.Method,
        _ transform: @escaping (Request) -> Response
    ) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: method, transform)
        } else {
            endpoint(method: method, transform)
        }
    }

    private func endpoint(subpath: String?, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(transform)
        } else {
            endpoint(transform)
        }
    }

    func add(_ subrouter: Router) {
        add("", subrouter)
    }

    func add(_ subpath: String = "", _ subrouter: Router) {
        subrouter.parent = self
        subrouter.subpath = subpath
        endpoints.append(.router(subrouter))
    }

    func filter(_ subpath: String) -> Router {
        let router = Router()
        add(subpath, router)
        return router
    }

    func any(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, transform)
    }

    func get(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .get, transform)
    }

    func post(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .post, transform)
    }

    func put(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .put, transform)
    }

    func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .delete, transform)
    }

    func map(_ transform: @escaping (Request) -> Request) -> Router {
        let newEndpoint = Endpoint(parent: self) { requests in
            (Signal<Response, ClientError>.empty, requests.map(transform))
        }
        let newTransformers = endpoints + [.endpoint(newEndpoint)]
        return Router(transformers: newTransformers)
    }

    func filter(_ predicate: @escaping (Request) -> Bool) -> Router {
        let middleware = RequestMiddleware(parent: self) { requests in
            requests.partition(predicate)
        }
        let newTransformers = endpoints + [.requestMiddleware(middleware)]
        return Router(transformers: newTransformers)
    }

    func transform(requests: Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        var forwardedRequests = requests
        let (allResponses, allResponsesInput) = Signal<Response, ClientError>.pipe()
        let (allRequests, allRequestsInput) = Signal<Request, ClientError>.pipe()
        for endpoint in endpoints {

            switch endpoint {
            case .router(let router):
                let (responses, unhandledRequests) = router.transform(requests: forwardedRequests)
                forwardedRequests = unhandledRequests
                responses.add(observer: allResponsesInput)

            case .endpoint(let endpoint):
                let (responses, unhandledRequests) = endpoint.transform(requests: forwardedRequests)
                forwardedRequests = unhandledRequests
                responses.add(observer: allResponsesInput)

            case .requestMiddleware(let requestMiddleware):
                let (transformedRequests, skippedRequests) =
                    requestMiddleware.transform(requests: forwardedRequests)
                forwardedRequests = transformedRequests
                skippedRequests.add(observer: allRequestsInput)

            }

        }
        forwardedRequests.add(observer: allRequestsInput)
        return (allResponses, allRequests)
    }

}

extension Router: CustomStringConvertible {

    public var description: String {
        return endpoints.map { $0.description }.joined(separator: "\n")
    }

}

enum RequestTransformer {
    case router(Router)
    case endpoint(Endpoint)
    case requestMiddleware(RequestMiddleware)
}

extension RequestTransformer: CustomStringConvertible {

    var description: String {
        switch self {
        case .router(let router):
            return router.description
        case .endpoint(let endpoint):
            return endpoint.description
        case .requestMiddleware(let requestMiddleware):
            return requestMiddleware.description
        }

    }

}

struct RequestMiddleware {

    typealias SourceType = Request
    typealias TransformedType = Request
    typealias ErrorType = ClientError

    weak var parent: Router?

    let transform: TransformType

    typealias TransformType = (Signal<Request, ClientError>)
        -> (Signal<Request, ClientError>, Signal<Request, ClientError>)

    func transform(requests: Signal<Request, ClientError>)
        -> (Signal<Request, ClientError>, Signal<Request, ClientError>) {
            return transform(requests)
    }

    init(parent: Router, _ transform: @escaping (Signal<Request, ClientError>)
        -> (Signal<Request, ClientError>, Signal<Request, ClientError>)) {
        self.transform = transform
        self.parent = parent
    }

    var path: String {
        return (parent?.path ?? "")
    }

}

extension RequestMiddleware: CustomStringConvertible {

    var description: String {
        return ""
    }

}

struct Endpoint {

    let method: HTTP.Method?
    weak var parent: Router?
    let transform: TransformType

    typealias TransformType = (Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>)

    func transform(requests: Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        return transform(requests)
    }

    init(parent: Router? = nil, method: HTTP.Method? = nil, _ transform: @escaping TransformType) {
        self.transform = transform
        self.parent = parent
        self.method = method
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
