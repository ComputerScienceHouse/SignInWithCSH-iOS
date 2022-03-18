import AppAuth
import Combine
import Foundation

extension Publisher {
    public func forwardToCompletion(
        _ handler: @escaping (Result<Output, Failure>) -> Void
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    handler(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { output in
                handler(.success(output))
            }
    }
}


extension OIDAuthorizationService {
    static func signIn(
        with configuration: CSHAppConfiguration,
        presentingViewController: UIViewController
    ) -> AnyPublisher<(OIDExternalUserAgentSession, OIDAuthState), Error> {
        Future { completion in
            OIDAuthorizationService
                .discoverConfiguration(
                    forIssuer: configuration.issuer
                ) { config, error in
                    guard let config = config else {
                        completion(.failure(error!))
                        return
                    }
                    var currentAuthFlow: OIDExternalUserAgentSession?
                    currentAuthFlow = OIDAuthState.authState(
                        byPresenting: OIDAuthorizationRequest(
                            configuration: config,
                            clientId: configuration.clientID,
                            clientSecret: "5c99723d-5d95-46c1-b234-0287221b2319",
                            scopes: configuration.scopes.map(\.rawValue),
                            redirectURL: configuration.redirectURL,
                            responseType: OIDResponseTypeCode,
                            additionalParameters: [
                                "prompt": "login"
                            ]
                        ),
                        presenting: presentingViewController
                    ) { authState, error in
                        guard let authState = authState else {
                            completion(.failure(error!))
                            return
                        }
                        completion(.success((currentAuthFlow!, authState)))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}

extension OIDAuthState {
    func formUserInfoRequest(forAccessToken accessToken: String) -> URLRequest {
        let userinfoEndpoint = lastAuthorizationResponse.request.configuration.discoveryDocument!.userinfoEndpoint!
        var urlRequest = URLRequest(url: userinfoEndpoint)
        urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
        return urlRequest
    }

    func refreshUserInfo() -> AnyPublisher<(OIDAuthState, Data, URLResponse), Error> {
        retrieveTokens()
            .flatMap { authState, accessToken, idToken in
                URLSession
                    .shared
                    .dataTaskPublisher(
                        for: authState.formUserInfoRequest(forAccessToken: accessToken)
                    )
                    .mapError { $0 as Error }
                    .map { data, response in (authState, data, response) }
            }
            .eraseToAnyPublisher()
    }

    func retrieveTokens() -> Future<(OIDAuthState, accessToken: String, idToken: String), Error> {
        Future { completion in
            self.performAction { accessToken, idToken, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success((self, accessToken!, idToken ?? "" )))
            }
        }
    }
}
