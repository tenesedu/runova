import SwiftUI

// MARK: - Onboarding Data Model
struct OnboardingData {
    var name: String = ""
    var age: Int = 18
    var username: String = ""
    var profileImage: UIImage?
}

// MARK: - Interactive Onboarding View
struct OnboardingView: View {
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
        /*
        UserService.checkUsernameAvailability(onboardingData.username) { available in
            withAnimation(.spring()) {
                isUsernameAvailable = available
                showUsernameValidation = true
            }
        }*/
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
                FloatingTextField(title: "Full Name", text: $data.name)
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
    OnboardingView()
}


// MARK: - GradientBackground
struct GradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - ProgressIndicator
struct ProgressIndicator: View {
    var currentStep: OnboardingStep
    
    var body: some View {
        VStack(spacing: 10) {
            Text(currentStep.title)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
            
            HStack(spacing: 4) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.purple : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .frame(width: UIScreen.main.bounds.width / CGFloat(OnboardingStep.allCases.count + 1))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - NavigationControls
struct NavigationControls: View {
    @Binding var currentStep: OnboardingStep
    var isNextEnabled: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            if currentStep != .personalInfo {
                Button(action: {
                    withAnimation(.spring()) {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .personalInfo
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            if currentStep == .profileImage {
                Button(action: onSubmit) {
                    Text("Finish")
                        .padding()
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .background(isNextEnabled ? Color.purple : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!isNextEnabled)
            } else {
                Button(action: {
                    withAnimation(.spring()) {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .profileImage
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(isNextEnabled ? Color.purple : Color.gray)
                    .clipShape(Capsule())
                }
                .disabled(!isNextEnabled)
            }
        }
        .padding()
        .padding(.bottom, 20)
    }
}

// MARK: - ValidationIndicator
struct ValidationIndicator: View {
    var isValid: Bool
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundColor(isValid ? .green : .red)
            .font(.title3)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - FloatingTextField
struct FloatingTextField: View {
    let title: String
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .foregroundColor(isEditing || !text.isEmpty ? .blue : .gray)
                .offset(y: isEditing || !text.isEmpty ? -25 : 0)
                .scaleEffect(isEditing || !text.isEmpty ? 0.8 : 1, anchor: .leading)
            
            TextField("", text: $text, onEditingChanged: { editing in
                withAnimation(.spring()) {
                    isEditing = editing
                }
            })
            .padding(.top, isEditing || !text.isEmpty ? 15 : 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isEditing ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
        )
        .animation(.spring(), value: isEditing)
    }
}

// MARK: - ProfileImageStep
struct ProfileImageStep: View {
    @Binding var image: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(spacing: 30) {
            AnimatedIcon(icon: "camera.fill", namespace: Namespace().wrappedValue)
            
            Text("Add a profile picture")
                .font(.title3)
                .fontWeight(.medium)
            
            ZStack {
                if let profileImage = image {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(width: 140, height: 140)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    sourceType = .camera
                    showImagePicker = true
                }) {
                    Label("Camera", systemImage: "camera")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }) {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerOn(image: $image, sourceType: sourceType)
        }
    }
}



// MARK: - ImagePicker
struct ImagePickerOn: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerOn
        
        init(parent: ImagePickerOn) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Helper Extension
extension OnboardingView {
    func isStepValid(step: OnboardingStep) -> Bool {
        switch step {
        case .personalInfo:
            return !onboardingData.name.isEmpty && onboardingData.name.count >= 2
        case .username:
            return isUsernameAvailable && onboardingData.username.count >= 4
        case .profileImage:
            return true // Opcional tener foto de perfil
        }
    }
}

