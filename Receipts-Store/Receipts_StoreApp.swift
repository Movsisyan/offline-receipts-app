//
//  Receipts_StoreApp.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

@main
struct Receipts_StoreApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Receipt.self,
            ReceiptItem.self
        ])
        
        // First try with normal configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If schema migration fails, try deleting the old store
            print("Failed to create ModelContainer: \(error)")
            print("Attempting to recreate database...")
            
            // Find and delete the old database
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                let walURL = appSupport.appendingPathComponent("default.store-wal")
                let shmURL = appSupport.appendingPathComponent("default.store-shm")
                
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: walURL)
                try? fileManager.removeItem(at: shmURL)
                
                print("Deleted old database files")
            }
            
            // Try again with fresh store
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
