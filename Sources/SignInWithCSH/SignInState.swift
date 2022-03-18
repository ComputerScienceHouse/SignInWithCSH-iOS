import AppAuth
import Combine
import Foundation

public struct SignInState: Codable {
    var authState: OIDAuthState
    public var user: CSHUser

    internal init(authState: OIDAuthState, user: CSHUser) {
        self.authState = authState
        self.user = user
    }
}

extension SignInState {
    enum CodingKeys: String, CodingKey {
        case authState
        case user
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)

        let archived = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
        try container.encode(archived, forKey: .authState)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let encodedAuthState = try container.decode(Data.self, forKey: .authState)
        self.authState = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(encodedAuthState) as! OIDAuthState
        self.user = try container.decode(CSHUser.self, forKey: .user)
    }
}

public struct CSHUser: Codable {
    public var sub: String
    public var name: String
    public var groups: [String]
    public var preferredUsername: String
    public var email: String
}
