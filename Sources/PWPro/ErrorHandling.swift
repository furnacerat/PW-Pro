import SwiftUI
import Foundation

// MARK: - Error Types

enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case validationError(String)
    case dataError(String)
    case businessLogicError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .businessLogicError(let message):
            return "Business Error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please sign in again or contact support if the problem persists."
        case .validationError:
            return "Please check your input and try again."
        case .dataError:
            return "Please try again. If the problem persists, contact support."
        case .businessLogicError:
            return "Please review your business rules and try again."
        case .unknownError:
            return "Please try again. If the problem persists, restart the app."
        }
    }
}

// MARK: - Error Manager

@MainActor
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var showError = false
    @Published var errors: [AppError] = []
    @Published var hasErrors = false
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: String = "") {
        let appError = mapToAppError(error, context: context)
        currentError = appError
        showError = true
        
        // Add to error log
        errors.append(appError)
        hasErrors = !errors.isEmpty
        
        // Log to console
        print("ErrorManager: \(appError.localizedDescription)")
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.currentError?.errorDescription == appError.errorDescription {
                self.dismissError()
            }
        }
    }
    
    func handleValidation(_ message: String) {
        let error = AppError.validationError(message)
        currentError = error
        showError = true
    }
    
    func handleNetwork(_ message: String) {
        let error = AppError.networkError(message)
        currentError = error
        showError = true
    }
    
    func handleAuth(_ message: String) {
        let error = AppError.authenticationError(message)
        currentError = error
        showError = true
    }
    
    func handleData(_ message: String) {
        let error = AppError.dataError(message)
        currentError = error
        showError = true
    }
    
    func handleBusinessLogic(_ message: String) {
        let error = AppError.businessLogicError(message)
        currentError = error
        showError = true
    }
    
    private func mapToAppError(_ error: Error, context: String) -> AppError {
        let message = error.localizedDescription
        
        if message.contains("network") || message.contains("offline") || message.contains("connection") {
            return .networkError(message)
        } else if message.contains("authentication") || message.contains("unauthorized") || message.contains("token") {
            return .authenticationError(message)
        } else if message.contains("validation") || message.contains("invalid") {
            return .validationError(message)
        } else if message.contains("data") || message.contains("parsing") || message.contains("encoding") {
            return .dataError(message)
        } else {
            return .unknownError(message)
        }
    }
    
    // MARK: - Error Management
    
    func dismissError() {
        currentError = nil
        showError = false
    }
    
    func clearErrors() {
        currentError = nil
        showError = false
        errors.removeAll()
        hasErrors = false
    }
    
    func removeError(_ error: AppError) {
        errors.removeAll { $0.errorDescription == error.errorDescription }
        hasErrors = !errors.isEmpty
    }
}

// MARK: - Success Manager

@MainActor
class SuccessManager: ObservableObject {
    static let shared = SuccessManager()
    
    @Published var currentSuccess: SuccessMessage?
    @Published var showSuccess = false
    @Published var successes: [SuccessMessage] = []
    
    private init() {}
    
    func showSuccess(title: String, message: String, type: SuccessType = .success) {
        let successMessage = SuccessMessage(title: title, message: message, type: type)
        currentSuccess = successMessage
        showSuccess = true
        
        // Add to success log
        successes.append(successMessage)
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.currentSuccess?.title == successMessage.title {
                self.dismissSuccess()
            }
        }
    }
    
    func dismissSuccess() {
        currentSuccess = nil
        showSuccess = false
    }
}

struct SuccessMessage {
    let title: String
    let message: String
    let type: SuccessType
    let timestamp = Date()
}

enum SuccessType {
    case success
    case warning
    case info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Toast Views

struct ErrorToast: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.errorDescription ?? "Error")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Button(action: {
                ErrorManager.shared.clearErrors()
                onDismiss()
            }) {
                Text("Clear All Errors")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SuccessToast: View {
    let message: SuccessMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: message.type.icon)
                .foregroundColor(message.type.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Loading States

struct LoadingView: View {
    let message: String?
    let showProgress: Bool
    let progress: Double?
    
    init(message: String? = nil, showProgress: Bool = false, progress: Double? = nil) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle())
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if showProgress, let progress = progress {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Empty State Views

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                
                Text("You're offline. Changes will sync when connection is restored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.orange.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Sync Status View

struct SyncStatusView: View {
    @ObservedObject var syncManager: OfflineSyncManager
    
    var body: some View {
        HStack {
            if syncManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if syncManager.pendingSyncCount > 0 {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.orange)
                Text("\(syncManager.pendingSyncCount) pending changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSync = syncManager.lastSyncDate {
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                Text("Synced \(lastSync, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "icloud")
                    .foregroundColor(.gray)
                Text("Not synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}