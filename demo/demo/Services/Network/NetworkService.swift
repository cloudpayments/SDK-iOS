import Alamofire
import AlamofireObjectMapper
import ObjectMapper

class NetworkService {
    
    private let sessionManager: SessionManager
    
    init(sessionManager: SessionManager = SessionManager.default) {
        self.sessionManager = sessionManager
    }
}

// MARK: - Internal methods

extension NetworkService {
    
    func makeObjectRequest<T: BaseMappable>(_ request: HTTPRequest, completion: @escaping (Result<T>) -> Void) {
        validatedDataRequest(from: request).responseObject(keyPath: request.mappingKeyPath) { completion($0.result) }
    }
    
    func makeArrayRequest<T: BaseMappable>(_ request: HTTPRequest, completion: @escaping (Result<[T]>) -> Void) {
        validatedDataRequest(from: request).responseArray(keyPath: request.mappingKeyPath) { completion($0.result) }
    }
}

// MARK: - Private methods

private extension NetworkService {
    
    func validatedDataRequest(from httpRequest: HTTPRequest) -> DataRequest {
        
        return sessionManager
            .request(httpRequest.resource,
                     method: httpRequest.method,
                     parameters: httpRequest.parameters,
                     encoding: JSONEncoding.default,
                     headers: httpRequest.headers)
            .validate()
    }
}
