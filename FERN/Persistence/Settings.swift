//
//  Settings.swift
//  FERN
//
//  Created by Hopp, Dan on 1/16/24.
//
//  10-JUN-2024: Add hdop threshold

import Foundation
import SwiftData

//// Version #s: The first number should change when something backward-incompatible is introduced, the second number should change when adding functionality that is backwards compatible, and the third should change when you make bug fixes.
//
//// Add a type alias so that the model name always points to whatever is your latest version:
//typealias Settings = SettingsSchemaV2.Settings
//
//// Versions:
//enum SettingsSchemaV1: VersionedSchema {
//    static var versionIdentifier = Schema.Version(1, 0, 0)
//    
//    static var models: [any PersistentModel.Type] {
//        [Settings.self]
//    }
//    
//    @Model
//    class Settings {
//        var databaseURL: String
//        var uploadScriptURL: String
//        
//        init(databaseURL: String = "https://127.0.0.1/folder", uploadScriptURL: String = "https://127.0.0.1/folder/file.php") {
//            self.databaseURL = databaseURL
//            self.uploadScriptURL = uploadScriptURL
//        }
//    }
//}

//enum SettingsSchemaV2: VersionedSchema {
//    static var versionIdentifier = Schema.Version(2, 0, 0)
//    
//    static var models: [any PersistentModel.Type] {
//        [Settings.self]
//    }
    
    @Model
    class Settings {
        var databaseURL: String
        var uploadScriptURL: String
        var cesiumURL: String
        var hdopThreshold: Double
        var useStandardGps: Bool
        
        init(databaseURL: String = "https://127.0.0.1/folder", 
             uploadScriptURL: String = "https://127.0.0.1/folder/file.php",
             cesiumURL: String = "https://127.0.0.1/folder/file.html",
             hdopThreshold: Double = 0,
             useStandardGps: Bool = false) {
            self.databaseURL = databaseURL
            self.uploadScriptURL = uploadScriptURL
            self.cesiumURL = cesiumURL
            self.hdopThreshold = hdopThreshold
            self.useStandardGps = useStandardGps
        }
    }
//}

// MARK: Code for migrations
//enum SettingsMigrationPlan: SchemaMigrationPlan {
//    static var schemas: [any VersionedSchema.Type] {
//        [SettingsSchemaV1.self, SettingsSchemaV2.self]
//    }
//    
//    // For a custom (aka "Heavy") migration, eg a non-unigue field is now unique
////    static let migrateV1toV2 = MigrationStage.custom(
////        fromVersion: SettingsSchemaV1.self,
////        toVersion: SettingsSchemaV2.self,
////        willMigrate: { context in
////            // do stuff then save
////            let settings = try context.fetch(FetchDescriptor<SettingsSchemaV1.Settings>())
////
////            var usedSettings = Set<String>()
////
////            for setting in settings {
////                if usedSettings.contains(setting.databaseURL) {
////                    context.delete(setting)
////                }
////
////                usedSettings.insert(setting.databaseURL)
////            }
////
////            try context.save()
////        }, didMigrate: nil
////    )
//    
//    // "Lightweight" migration, E.g. a new field has been added to a model.
////    static let migrateV1toV2 = MigrationStage.lightweight(
////        fromVersion: SettingsSchemaV1.self,
////        toVersion: SettingsSchemaV2.self
////    )
//    
//    static let migrateV1toV2 = MigrationStage.custom(
//        fromVersion: SettingsSchemaV1.self,
//        toVersion: SettingsSchemaV2.self,
//        willMigrate: nil, didMigrate: nil
//    )
//    
//    static var stages: [MigrationStage] {
//        [migrateV1toV2]
//    }
//}
