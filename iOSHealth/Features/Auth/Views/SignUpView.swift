import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient.vitalyGradient)
                            .frame(width: 100, height: 100)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }

                    Text("Skapa konto")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Registrera dig för att börja spåra din hälsa")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    // Phone input and verification handled by LoginView
                    NavigationLink {
                        LoginView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                            Text("Fortsätt med telefonnummer")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.vitalyGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
        }
    }
}
