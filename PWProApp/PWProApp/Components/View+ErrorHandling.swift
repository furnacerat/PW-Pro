import SwiftUI

struct ErrorHandlingModifier: ViewModifier {
    @Binding var error: String?
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let errorMessage = error {
                VStack {
                    ErrorBanner(message: errorMessage) {
                        withAnimation {
                            error = nil
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100) // Ensure it floats above everything
                    .padding(.top, 8) // Add some spacing from top safe area
                    
                    Spacer()
                }
            }
        }
    }
}

extension View {
    func withErrorHandling(error: Binding<String?>) -> some View {
        self.modifier(ErrorHandlingModifier(error: error))
    }
}
