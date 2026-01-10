import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIds = ["com.sid.clipboard.pro"]
    private var updates: Task<Void, Never>? = nil
    
    private let trialManager = TrialManager.shared
    
    init() {
        updates = newTransactionListenerTask()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func requestProducts() async {
        do {
            let products = try await Product.products(for: productIds)
            self.products = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if let transaction = try? verification.payloadValue {
                await transaction.finish()
                purchasedProductIDs.insert(transaction.productID)
                if transaction.productID == "com.sid.clipboard.pro" {
                    trialManager.unlockPro()
                }
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        await updateCustomerProductStatus()
    }
    
    func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                purchasedProductIDs.insert(transaction.productID)
                if transaction.productID == "com.sid.clipboard.pro" {
                    trialManager.unlockPro()
                }
            }
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await updateCustomerProductStatus()
                }
            }
        }
    }
}
