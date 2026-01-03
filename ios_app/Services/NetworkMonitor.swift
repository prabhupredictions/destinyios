import Foundation
import Combine
import Network
import SwiftUI

/// Monitors network connectivity and publishes status changes
/// Used to show offline indicator in UI when device has no internet
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline Banner View

/// A subtle banner that appears when device is offline
struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("offline_mode".localized)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.9))
            .cornerRadius(16)
        }
    }
}

#Preview {
    OfflineBanner()
        .padding()
}

