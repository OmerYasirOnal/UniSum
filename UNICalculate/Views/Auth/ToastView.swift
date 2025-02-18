import SwiftUI

struct Toast: Equatable {
    let message: LocalizedStringKey
    let type: ToastType
    
    init(stringMessage: String, type: ToastType) {
        self.message = LocalizedStringKey(stringMessage)
        self.type = type
    }
    
    init(message: LocalizedStringKey, type: ToastType) {
        self.message = message
        self.type = type
    }
    
    enum ToastType {
        case error
        case success
        case info
        
        var backgroundColor: Color {
            switch self {
            case .error: return .red
            case .success: return .green
            case .info: return .blue
            }
        }
    }
}

struct ToastView: View {
    let toast: Toast
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text(toast.message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
                .padding(.trailing)
            }
            .background(toast.type.backgroundColor.opacity(0.9))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}
