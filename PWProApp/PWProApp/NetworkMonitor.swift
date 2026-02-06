import SwiftUI
import Network

/// Monitors network connectivity and provides offline status
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}

// MARK: - Offline Banner View

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're Offline")
                            .font(.subheadline.bold())
                        Text("Some features may be unavailable")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Force refresh - user can pull to refresh most views
                        HapticManager.notification(.warning)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Theme.amber500, Theme.amber500.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Theme.amber500.opacity(0.3), radius: 10, y: 5)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: networkMonitor.isConnected)
    }
}

// MARK: - View Modifier for Offline Awareness

struct OfflineAwareModifier: ViewModifier {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineBanner()
            content
        }
    }
}

extension View {
    /// Adds an offline banner at the top when network is unavailable
    func offlineAware() -> some View {
        self.modifier(OfflineAwareModifier())
    }
}
