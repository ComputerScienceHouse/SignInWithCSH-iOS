import SwiftUI

struct AppAuthModifier: ViewModifier {
    var authorizer: CSHAuthorizer
    @Binding var isPresented: Bool

    func finish(_ result: Result<SignInState, Error>) {
        isPresented = false
    }

    @ViewBuilder
    var presentedOverlay: some View {
        if isPresented {
            AppAuthAdaptor(modifier: self)
                .id(UUID())
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay(presentedOverlay)
    }
}

extension View {
    public func cshAuthenticationSheet(
        authorizer: CSHAuthorizer,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            AppAuthModifier(
                authorizer: authorizer,
                isPresented: isPresented
            )
        )
    }
}

private struct AppAuthAdaptor: UIViewControllerRepresentable {
    final class ShimViewController: UIViewController {
        var modifier: AppAuthModifier
        init(modifier: AppAuthModifier) {
            self.modifier = modifier
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            let presentedBinding = modifier.$isPresented
            modifier.authorizer.signInIfNecessary(presentedBy: self) {
                presentedBinding.wrappedValue = false
            }
        }
    }
    var modifier: AppAuthModifier

    func makeUIViewController(context: Context) -> ShimViewController {
        ShimViewController(modifier: modifier)
    }

    func updateUIViewController(_ view: ShimViewController, context: Context) {
    }
}
