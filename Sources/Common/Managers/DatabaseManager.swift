//
//  DatabaseManager.swift
//  Pomodoro
//
//  Created by 김현기 on 2/24/24.
//

import Foundation
import RealmSwift

protocol DataBase {
    func read<T: Object>(_ object: T.Type) -> Results<T>
    func write<T: Object>(_ object: T)
    func delete<T: Object>(_ object: T)
    func sort<T: Object>(_ object: T.Type, by keyPath: String, ascending: Bool) -> Results<T>
}

final class DatabaseManager: DataBase {
    static let shared = DatabaseManager()

    private var database: Realm?

    private init() {
        print("Database Init")
        do {
            database = try Realm()
            createPomodoro(tag: "study")
        } catch {
            print("Error initalizing Realm: \(error)")
        }
    }

    func getLocationOfDefaultRealm() {
        print("Realm is located at:", database!.configuration.fileURL!)
    }

    func read<T: Object>(_ object: T.Type) -> Results<T> {
        database!.objects(object)
    }

    func createPomodoro(tag: String) {
        var id = 0
        if let lastPomodoro = database?.objects(Pomodoro.self).last {
            id = lastPomodoro.id + 1
        }

        let pomodoro = Pomodoro(id: id, phase: 1, currentTag: tag, participateDate: Date.now)

        write(pomodoro)
    }

    func write(_ object: some Object) {
        do {
            try database!.write {
                database!.add(object, update: .modified)
            }

        } catch {
            print(error)
        }
    }

    func update<T: Object>(_ object: T, completion: @escaping ((T) -> Void)) {
        do {
            try database!.write {
                completion(object)
            }

        } catch {
            print(error)
        }
    }

    func delete(_ object: some Object) {
        do {
            try database!.write {
                database!.delete(object)
                print("Delete Success")
            }

        } catch {
            print(error)
        }
    }

    func deleteAll() {
        do {
            try database!.write {
                database?.deleteAll()
            }

        } catch {
            print(error)
        }
    }

    func sort<T: Object>(_ object: T.Type, by keyPath: String, ascending: Bool = true) -> Results<T> {
        database!.objects(object).sorted(byKeyPath: keyPath, ascending: ascending)
    }
}
