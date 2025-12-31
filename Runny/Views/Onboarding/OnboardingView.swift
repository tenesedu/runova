import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage

extension AnyTransition {
    static var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - Interactive Onboarding View
struct OnboardingView: View {
   
    
    enum OnboardingStep: Int, CaseIterable {
        case personalInfo, username, profileImage, gender, city, goals, interests, location
        
        var title: String {
            switch self {
            case .personalInfo: return "About You"
            case .username: return "Create Your ID"
            case .profileImage: return "Your Profile"
            case .gender: return "Your Gender"
            case .city: return "Your City"
            case .goals: return "Your Goals"
            case .interests: return "Your Interests"
            case .location: return "Enable Location"
            }
        }
    }
    
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep: OnboardingStep = .personalInfo
    @State private var showUsernameValidation = false
    @State private var isUsernameAvailable = false
    @State private var showImagePicker = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                ProgressIndicator(currentStep: currentStep)
                
                Group {
                    switch currentStep {
                    case .personalInfo:
                        PersonalInfoStep(name: $viewModel.onboardingData.name,age: $viewModel.onboardingData.age, namespace: animationNamespace)
                            .transition(.stepTransition)
                    case .username:
                        UsernameStep(
                            username: $viewModel.onboardingData.username,
                            isAvailable: $isUsernameAvailable,
                            validateAction: validateUsername
                        )
                        .transition(.stepTransition)
                    case .profileImage:
                        ProfileImageStep(image: $viewModel.onboardingData.profileImage, showImagePicker: $showImagePicker)
                            .transition(.stepTransition)
                    case .gender:
                        GenderStep(gender: $viewModel.onboardingData.gender)
                            .transition(.stepTransition)
                    case .city:
                        CityStep(city: $viewModel.onboardingData.city)
                            .transition(.stepTransition)
                    case .goals:
                        GoalsStep(goals: $viewModel.onboardingData.goals)
                            .transition(.stepTransition)
                    case .interests:
                        InterestsStep(interests: $viewModel.onboardingData.interests)
                            .transition(.stepTransition)
                    case .location:
                        LocationStep(locationEnabled: $viewModel.onboardingData.locationEnabled)
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
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func validateUsername() {
        Task {
            await validateUsernameAsync()
        }
    }

  
    private func validateUsernameAsync() async {
        guard !viewModel.onboardingData.username.isEmpty else { return }
        
        let available = await UserService.shared.checkUsernameAvailability(viewModel.onboardingData.username)
    
        withAnimation(.spring()) {
            isUsernameAvailable = available
            showUsernameValidation = true
        }
    }

    
    
    private func completeOnboarding() {
        viewModel.completeOnboarding(selectedImage: viewModel.onboardingData.profileImage)
    }

    
    private func isStepValid(step: OnboardingStep) -> Bool {
        switch step {
        case .personalInfo:
            return !viewModel.onboardingData.name.isEmpty && viewModel.onboardingData.name.count >= 2
        case .username:
            return isUsernameAvailable && viewModel.onboardingData.username.count >= 4
        case .profileImage:
            return true // Opcional tener foto de perfil
        case .gender:
            return !viewModel.onboardingData.gender.isEmpty
        case .city:
            return !viewModel.onboardingData.city.isEmpty
        case .goals:
            return viewModel.onboardingData.goals.count >= 1
        case .interests:
            return viewModel.onboardingData.interests.count >= 1
        case .location:
            return true // Opcional
        }
    }
}


// MARK: - Previews
#Preview {
    OnboardingView()
}
