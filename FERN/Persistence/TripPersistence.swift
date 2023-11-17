//
//  TripCoreData.swift
//  FERN
//
//  Created by Hopp, Dan on 11/15/23.
//
// Msgs:
// Changing the translatesAutoresizingMaskIntoConstraints property of a UICollectionViewCell that is managed by a UICollectionView is not supported, and will result in incorrect self-sizing.
//
// passing photo
// 2023-11-15 15:28:40.049317-0500 FERN[753:95518] Errors found! Invalidating cache...

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<1 {
            let newItem = Trip(context: viewContext)
            newItem.name = "From preview var"
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print(nsError.localizedDescription)
            print("struct PersistenceController static var preview error \(error), \(error.localizedDescription)")
        }

        return result
    }()

    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CoreData")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print(error.localizedDescription)
                print("init loadPersistentStores error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
}
