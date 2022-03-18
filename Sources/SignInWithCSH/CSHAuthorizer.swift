import AppAuth
import Combine
import Foundation

let userDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    return d
}()

public final class CSHAuthorizer: NSObject, ObservableObject, OIDAuthStateChangeDelegate {
    public enum State {
        case unauthorized
        case authorized(SignInState)
        case authorizationFailed(Error)
    }
    
    public enum AuthorizationError: Swift.Error {
        case unauthorized
    }
    static let userDataKey = "edu.rit.csh.SignInState"
    var configuration: CSHAppConfiguration
    var authFlow: OIDExternalUserAgentSession?
    @Published public var signInState = State.unauthorized

    public init(_ configuration: CSHAppConfiguration) {
        self.configuration = configuration
        super.init()
        loadAuthState()
    }

    func loadAuthState() {
        guard let stateData = UserDefaults.standard.data(forKey: CSHAuthorizer.userDataKey) else {
            signInState = .unauthorized
            return
        }

        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(SignInState.self, from: stateData)
            signInState = .authorized(state)
        } catch {
            signInState = .unauthorized
        }
    }

    func saveAuthState(_ state: SignInState) {
        let encoded = try! JSONEncoder().encode(state)
        UserDefaults.standard.set(encoded, forKey: CSHAuthorizer.userDataKey)
    }

    var cancellables = Set<AnyCancellable>()

    private func handleResult(_ result: Result<SignInState, Error>) {
        switch result {
        case .failure(let error):
            self.signInState = .authorizationFailed(error)
        case .success(let state):
            self.signInState = .authorized(state)
            saveAuthState(state)
        }
    }

    public func signOut() {
        UserDefaults.standard.removeObject(forKey: CSHAuthorizer.userDataKey)
        if case .authorized(let signIn) = signInState {
            signIn.authState.stateChangeDelegate = nil
        }
        authFlow = nil
        signInState = .unauthorized
    }

    public func didChange(_ state: OIDAuthState) {
        state.refreshUserInfo()
            .tryMap { state, data, _ in
                SignInState(
                    authState: state,
                    user: try userDecoder.decode(CSHUser.self, from: data)
                )
            }
            .forwardToCompletion(handleResult)
            .store(in: &cancellables)
    }

    func signInIfNecessary(
        presentedBy viewController: UIViewController,
        completion: @escaping () -> Void
    ) {
        if case .authorized = signInState {
            return
        }

        OIDAuthorizationService.signIn(
            with: configuration,
            presentingViewController: viewController
        )
        .map { [weak self] authFlow, state -> OIDAuthState in
            if let self = self {
                self.authFlow = authFlow
                state.stateChangeDelegate = self
            }
            return state
        }
        .flatMap { state in
            return state.refreshUserInfo()
        }
        .tryMap { state, data, _ in
            SignInState(
                authState: state,
                user: try userDecoder.decode(CSHUser.self, from: data)
            )
        }
        .map { state -> SignInState in
            completion()
            return state
        }
        .forwardToCompletion(handleResult)
        .store(in: &cancellables)
    }


    public func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        guard case .authorized(let signIn) = signInState else {
            return Future { completion in
                completion(.failure(AuthorizationError.unauthorized))
            }
            .eraseToAnyPublisher()
        }

        return signIn
            .authState
            .retrieveTokens()
            .flatMap { authState, accessToken, idToken -> AnyPublisher<(data: Data, response: URLResponse), Error> in
                var request = request
                request.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
                return URLSession
                    .shared
                    .dataTaskPublisher(for: request)
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func dataTaskPublisher(for url: URL)
    -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        dataTaskPublisher(for: URLRequest(url: url))
    }
}
