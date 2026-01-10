import SwiftUI
import StoreKit

struct UpgradeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Pro")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your 7-day free trial has expired.\nGet unlimited clipboard history forever.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
            
            if let product = storeManager.products.first {
                Button(action: {
                    Task {
                        try? await storeManager.purchase(product)
                    }
                }) {
                    Text("Buy Lifetime Access for \(product.displayPrice)")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                ProgressView("Loading products...")
            }
            
            Button("Restore Purchases") {
                Task {
                    await storeManager.restorePurchases()
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            
            Button("Quit App") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 10)
        }
        .padding(40)
        .frame(width: 400, height: 450)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

// Helper for Visual Effect Background
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
