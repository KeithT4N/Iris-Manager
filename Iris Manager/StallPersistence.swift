//
// Created by Keith Tan on 5/14/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Moya
import RealmSwift
import ObjectMapper
import Moya_ObjectMapper

protocol StallUpdateDelegate {
    func onUpdateFinish()

    func onUpdateFail()
}

class StallPersistence {

    static func create(stallName: String, onSuccess: @escaping (Stall) -> Void) {

        let requestCreator = IrisProvider.RequestCreator(onSuccess: { response in
            guard let stall = Deserializer.toStall(response: response) else {
                return
            }

            log.verbose("Create stall success")

            LocalDatabase.saveToRealm(stall: stall, isUpdate: false)
            onSuccess(stall)
        })

        requestCreator.request(for: .createStall(stallName: stallName))
    }

    static func modify(oldStall old: Stall, newStall new: Stall, onSuccess: @escaping () -> Void) {

        let requestCreator = IrisProvider.RequestCreator(onSuccess: { _ in

            log.verbose("Edit stall success")

            LocalDatabase.modify(oldStall: old, newStall: new)

            onSuccess()
        })

        requestCreator.request(for: .modifyStall(stall: new))
    }

    static func delete(stall: Stall, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {

        let onSuccess: (Response) -> Void = { _ in
            LocalDatabase.deleteStall(stall: stall)

            onSuccess()
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onSuccess, onGeneralFailure: onFailure)
        
        requestCreator.request(for: .deleteStall(id: stall.id))
    }

    static func updateLocalDatabase(delegate: StallUpdateDelegate) {

        guard !UpdateManager.isRunning else {
            log.warning("Attempt to run stall update while update still running")
            delegate.onUpdateFail()
            return
        }



        log.info("Retrieving Stall Updates...")
        UpdateManager(delegate: delegate).update()
    }

    static func getAllStalls() -> [Stall] {
        return LocalDatabase.getStalls()
    }



    //MARK: - Stall Update Structure

    fileprivate struct StallUpdateStructure: Mappable {
        var id:          Int  = 0
        var lastUpdated: Date = Date()

        init? (map: Map) {
        }

        init(id: Int, lastUpdated: Date) {
            self.id = id
            self.lastUpdated = lastUpdated
        }

        mutating func mapping(map: Map) {
            id <- map["id"]
            lastUpdated = try! map.value("last_updated",
                                         using: CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"))
        }
    }

    fileprivate class UpdateManager {

        var delegate: StallUpdateDelegate
        fileprivate static var isRunning: Bool = false

        init(delegate: StallUpdateDelegate) {
            self.delegate = delegate
        }

        func onUpdateFail() {
            UpdateManager.isRunning = false
            delegate.onUpdateFail()
        }

        func update() {
            UpdateManager.isRunning = true
            let requestCreator = IrisProvider.RequestCreator(onSuccess: self.onUpdateStructureResponse,
                                                             onGeneralFailure: self.onUpdateFail)
            requestCreator.request(for: .getStallUpdates)
        }

        func onUpdateStructureResponse(response: Response) {
            guard let stallUpdates = Deserializer.toStallUpdateStructureArray(response: response) else {
                self.onUpdateFail()
                return
            }

            self.fetchUpdates(for: stallUpdates)
        }

        func fetchUpdates(for updateStructures: [StallUpdateStructure]) {
            let currentStalls                                      = LocalDatabase.getStalls()
            var stallsToRetrieve: [(stallID: Int, isUpdate: Bool)] = []
            var stallsToDelete:   [Int]                            = []
            var updateStructures                                   = updateStructures

            for currentStall in currentStalls {

                guard let index = updateStructures.index(where: { $0.id == currentStall.id }) else {
                    //If ID is not present in updateStructures, the stall must have been deleted.
                    stallsToDelete.append(currentStall.id)
                    continue
                }

                let stallUpdate = updateStructures[index]

                if currentStall.lastUpdated < stallUpdate.lastUpdated {
                    stallsToRetrieve.append((stallID: stallUpdate.id, isUpdate: true))
                }


                //Remove all that are already examined
                //Will leave only new stalls
                updateStructures.remove(at: index)

            }

            //Items remaining must be new.
            updateStructures.forEach { structure in
                stallsToRetrieve.append((stallID: structure.id, isUpdate: false))
            }

            //Let's update!
            delete(stalls: stallsToDelete)
            retrieve(stalls: stallsToRetrieve)
        }

        func delete(stalls: [Int]) {
            stalls.forEach { stallID in
                log.verbose("Deleting local Stall ID \(stallID)...")
                let stall = LocalDatabase.getStall(id: stallID)! //We know this exists.
                LocalDatabase.deleteStall(stall: stall)
            }
        }

        func retrieve(stalls: [(stallID: Int, isUpdate: Bool)]) {
            let queue = DispatchQueue(label: "com.iris-manager.stall-retrieval", attributes: .concurrent, target: .main)
            let group = DispatchGroup()

            queue.async(group: group) {
                stalls.forEach { id, isUpdate in
                    group.enter()
                    log.verbose("Retrieving Stall ID \(id), isUpdate: \(isUpdate)...")
                    self.saveFromServer(stallID: id, isUpdate: isUpdate) {
                        group.leave()
                    }
                }
            }

            group.notify(queue: DispatchQueue.main) {
                self.delegate.onUpdateFinish()
                UpdateManager.isRunning = false
            }


        }


        func saveFromServer(stallID: Int, isUpdate: Bool, completion: @escaping () -> Void) {

            let onSuccess: (Response) -> Void = { response in

                defer { completion() }

                guard let stall = Deserializer.toStall(response: response) else {
                    self.onUpdateFail()
                    return
                }

                LocalDatabase.saveToRealm(stall: stall, isUpdate: isUpdate)
            }


            let onFailure: () -> Void = {
                self.onUpdateFail()
                completion()
            }

            let requestCreator = IrisProvider.RequestCreator(onSuccess: onSuccess, onGeneralFailure: onFailure)

            requestCreator.request(for: .getStall(id: stallID))
        }


    }


    //MARK: - Deserializer

    fileprivate class Deserializer {

        static func toStall(response: Response) -> Stall? {
            do {
                return try response.mapObject(Stall.self)
            } catch {
                handleDeserializationError(error: error, response: response)
                return nil
            }
        }

        static func toStallArray(response: Response) -> [Stall]? {
            do {
                return try response.mapArray(Stall.self)
            } catch {
                handleDeserializationError(error: error, response: response)
                return nil
            }
        }

        static func toStallUpdateStructureArray(response: Response) -> [StallUpdateStructure]? {
            do {
                return try response.mapArray(StallUpdateStructure.self)
            } catch {
                handleDeserializationError(error: error, response: response)
                return nil
            }
        }

        static func handleDeserializationError(error: Swift.Error, response: Response) {
            log.error("An error occurred deserializing stall.")
            log.error(error.localizedDescription)
            let responseString = String(data: response.data, encoding: .utf8) ?? "No response."
            log.error("Response String: \(responseString)")
        }
    }

    //MARK: - Local Database

    fileprivate class LocalDatabase {

        static var realm: Realm {
            return try! Realm()
        }

        static func modify(oldStall old: Stall, newStall new: Stall) {
            try! self.realm.write {
                old.name = new.name
            }
        }

        static func getStall(id: Int) -> Stall? {
            return self.realm.objects(Stall.self).filter("id == \(id)").first
        }

        static func saveToRealm(stall: Stall, isUpdate: Bool) {
            try! self.realm.write {
                self.realm.add(stall, update: isUpdate)
            }
        }

        static func getStalls() -> [Stall] {
            return Array(self.realm.objects(Stall.self))
        }

        static func deleteStall(stall: Stall) {
            try! self.realm.write {
                self.realm.delete(stall)
            }
        }

    }

}
