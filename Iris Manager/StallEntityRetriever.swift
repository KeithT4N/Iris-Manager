//
// Created by Keith Tan on 4/29/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Moya
import ObjectMapper
import Moya_ObjectMapper
import RealmSwift

class StallEntityRetriever {

    static let shared = StallEntityRetriever()
    let realm = try! Realm()


    fileprivate init() {
    }

    func updateLocalDatabase() {
        print("Retrieving stall updates...")
        request(for: .getStallUpdates) { response in
            do {
                let stallUpdates = try response.mapArray(StallUpdateSkeleton.self)
                print("Success.")
                self.fetchNewUpdates(newUpdateSkeletons: stallUpdates)
            } catch {
                //TODO: Failure Case
            }
        }
    }

    fileprivate func fetchNewUpdates(newUpdateSkeletons: [StallUpdateSkeleton]) {

        let currentStalls = realm.objects(Stall.self)

        var stallsToUpdate: [Int] = []
        var stallsToAdd:    [Int] = []

        for updateSkeleton in newUpdateSkeletons {
            guard let index = currentStalls.index(where: { $0.id == updateSkeleton.id }) else {
                stallsToAdd.append(updateSkeleton.id) //Stall must be new
                continue
            }

            let currentStall = currentStalls[index]

            if currentStall.lastUpdated < updateSkeleton.lastUpdated {
                stallsToUpdate.append(updateSkeleton.id) //Stall must be outdated
            }
        }

        print("Stalls to update: \(stallsToUpdate)")
        print("Stalls to add: \(stallsToAdd)")

        stallsToUpdate.forEach { id in
            getStall(id: id, isUpdate: true)
        }

        stallsToAdd.forEach { id in
            getStall(id: id, isUpdate: false)
        }
    }

    fileprivate func getStall(id: Int, isUpdate: Bool) {
        request(for: .getStall(id: id)) { response in

            do {
                let stall = try response.mapObject(Stall.self)

                try! self.realm.write {
                    self.realm.add(stall, update: isUpdate)
                }

            } catch {
                print("An error occurred mapping json to Stall Object")
                print(error.localizedDescription)
                print("Response Code: \(response.statusCode)")
                print("Response JSON: \(String(data: response.data, encoding: .utf8) ?? "No data")")
            }
        }
    }

}
