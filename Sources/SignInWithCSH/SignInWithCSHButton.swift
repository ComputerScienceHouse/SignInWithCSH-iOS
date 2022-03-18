import SwiftUI

extension Color {
    public static var cshPink: Color {
        Color(.sRGB, red: 176/255, green: 25/255, blue: 126/255, opacity: 1)
    }
}

public struct SignInWithCSHButton: View {
    struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.cshPink)
                .overlay(
                    configuration.isPressed ?
                        Color.black.opacity(0.1)
                                .transition(.opacity)
                                .animation(.spring()) :
                        nil
                )
                .cornerRadius(8)
        }
    }
    var authorizer: CSHAuthorizer
    @State var isPresentingAuthSheet = false

    public init(_ authorizer: CSHAuthorizer) {
        self.authorizer = authorizer
    }

    public var body: some View {
        Button("Sign in with CSH") {
            isPresentingAuthSheet = true
        }
        .cshAuthenticationSheet(
            authorizer: authorizer,
            isPresented: $isPresentingAuthSheet
        )
        .buttonStyle(Style())
    }
}
