import SwiftUI
import Lottie

// MARK: - Onboarding Data Model
struct OnboardingData {
    var name: String = ""
    var age: Int = 18
    var username: String = ""
    var profileImage: UIImage?
}

// MARK: - Interactive Onboarding View
struct InteractiveOnboardingView: View {
    @State private var currentStep: OnboardingStep = .personalInfo
    @State private var onboardingData = OnboardingData()
    @State private var showUsernameValidation = false
    @State private var isUsernameAvailable = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            GradientBackground() // Vista personalizada con gradiente animado
            
            VStack(spacing: 0) {
                ProgressIndicator(currentStep: currentStep)
                
                Group {
                    switch currentStep {
                    case .personalInfo:
                        PersonalInfoStep(data: $onboardingData, namespace: animationNamespace)
                            .transition(.stepTransition)
                    case .username:
                        UsernameStep(
                            username: $onboardingData.username,
                            isAvailable: $isUsernameAvailable,
                            validateAction: validateUsername
                        )
                        .transition(.stepTransition)
                    case .profileImage:
                        ProfileImageStep(image: $onboardingData.profileImage)
                            .transition(.stepTransition)
                    }
                }
                .padding(.horizontal)
                
                NavigationControls(
                    currentStep: $currentStep,
                    isNextEnabled: isStepValid(step: currentStep),
                    onSubmit: completeOnboarding
                )
            }
        }
    }
    
    // Validación en tiempo real del username
    private func validateUsername() {
        guard !onboardingData.username.isEmpty else { return }
        
        UserService.checkUsernameAvailability(onboardingData.username) { available in
            withAnimation(.spring()) {
                isUsernameAvailable = available
                showUsernameValidation = true
            }
        }
    }
    
    private func completeOnboarding() {
        // Lógica para guardar datos
    }
}

// MARK: - Pasos del Onboarding
enum OnboardingStep: Int, CaseIterable {
    case personalInfo, username, profileImage
    
    var title: String {
        switch self {
        case .personalInfo: return "About You"
        case .username: return "Create Your ID"
        case .profileImage: return "Your Profile"
        }
    }
}

// MARK: - Componente: Paso de Información Personal
struct PersonalInfoStep: View {
    @Binding var data: OnboardingData
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 25) {
            // Animación de icono coordinada
            AnimatedIcon(icon: "person.fill", namespace: namespace)
            
            VStack(spacing: 15) {
                FloatingTextField("Full Name", text: $data.name)
                    .keyboardType(.namePhonePad)
                
                AgeSelector(age: $data.age)
            }
        }
    }
}

// MARK: - Componente: Selector de Edad Interactivo
struct AgeSelector: View {
    @Binding var age: Int
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack {
            Text("Age: \(age)")
                .font(.title2)
                .fontWeight(.semibold)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 60)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let width = value.translation.width
                                let maxAge: CGFloat = 100
                                let scaleFactor = UIScreen.main.bounds.width / maxAge
                                age = min(max(18, Int(width / scaleFactor) + 18), 100)
                            }
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 30)
                    .offset(x: offset.width)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset.width = value.translation.width
                                let maxAge: CGFloat = 100
                                let scaleFactor = UIScreen.main.bounds.width / maxAge
                                age = min(max(18, Int(value.translation.width / scaleFactor) + 18), 100)
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                            }
                    )
            }
        }
    }
}

// MARK: - Componente: Validación de Username
struct UsernameStep: View {
    @Binding var username: String
    @Binding var isAvailable: Bool
    var validateAction: () -> Void
    
    @State private var pulsate = false
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "at", namespace: Namespace().wrappedValue)
            
            VStack(spacing: 10) {
                HStack {
                    TextField("@username", text: $username)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username) { _ in
                            validateAction()
                        }
                    
                    ValidationIndicator(isValid: isAvailable)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(isAvailable ? Color.green : Color.red, lineWidth: 2)
                )
                
                Text("Must be unique • 4-20 characters • Letters and numbers only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Animaciones Personalizadas
extension AnyTransition {
    static var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

struct AnimatedIcon: View {
    let icon: String
    var namespace: Namespace.ID
    
    var body: some View {
        Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .padding(20)
            .background(
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                    .matchedGeometryEffect(id: "iconBackground", in: namespace)
            )
            .foregroundColor(.white)
    }
}

// MARK: - Previews
#Preview {
    InteractiveOnboardingView()
}
