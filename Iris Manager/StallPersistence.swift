//
// Created by Keith Tan on 5/14/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Moya
import RealmSwift
import ObjectMapper
import Moya_ObjectMapper
import ObjectMapper

protocol StallUpdateDelegate {
    func onUpdateFinish()

    func onUpdateFail()
}

class StallPersistence {

    static func create(stallName: String, onSuccess: @escaping (Stall) -> Void, onFailure: @escaping () -> Void) {

        let onStallCreationSuccess: (Response) -> Void = { response in

            guard let stall = Deserializer.toStall(response: response) else {
                onFailure()
                return
            }

            log.verbose("Create stall success")

            onSuccess(stall)
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onStallCreationSuccess,
                                                         onGeneralFailure: onFailure)

        requestCreator.request(for: .createStall(stallName: stallName))
    }

    static func modify(newStall new: Stall, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        
        let onResponse: (Response) -> Void = { _ in
            
            log.verbose("Edit stall success")
            
            let oldStall = LocalDatabase.getStall(id: new.id)!
            LocalDatabase.modify(oldStall: oldStall, newStall: new)
            
            onSuccess()
        }
        

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onResponse, onGeneralFailure: onFailure)

        requestCreator.request(for: .modifyStall(stall: new))
    }

    static func delete(id: Int, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {

        let onSuccess: (Response) -> Void = { _ in
            LocalDatabase.delete(id: id)

            //TODO: Update Local Database
            onSuccess()
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onSuccess, onGeneralFailure: onFailure)

        requestCreator.request(for: .deleteStall(id: id))
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

    fileprivate class UpdateManager {

        var delegate: StallUpdateDelegate
        fileprivate static var isRunning: Bool = false

        init(delegate: StallUpdateDelegate) {
            self.delegate = delegate
        }

        func onUpdateFail() {
            UpdateManager.isRunning = false
            self.delegate.onUpdateFail()
        }

        func onUpdateFinish() {
            UpdateManager.isRunning = false
            self.delegate.onUpdateFinish()
        }

        func update() {
            //TODO: Create user settings signifying last update
            UpdateManager.isRunning = true

            guard let lastUpdated = ModelType.stalls.lastUpdated else {
                log.verbose("No last update found. Initializing database...")
                self.initializeDatabase()
                return
            }
            
            log.verbose("Last updated \(lastUpdated), fetching updates...")

            self.requestUpdates(from: lastUpdated)
        }

        //No history of updates? Fetch everything.
        func initializeDatabase() {

            let onRequestSuccess: (Response) -> Void = { response in
                
                guard let stalls = Deserializer.toStallArray(response: response) else {
                    self.onUpdateFail()
                    return
                }
                
                LocalDatabase.save(stalls: stalls, isUpdate: false)
                UpdateManager.isRunning = false
                
                let dateNow = Date()
                log.info("Updating last updated for Stall")
                ModelType.stalls.setLastUpdated(dateNow)
                
                log.info("Local database initialization complete")

                self.onUpdateFinish()
            }

            let requestCreator = IrisProvider.RequestCreator(onSuccess: onRequestSuccess,
                                                             onGeneralFailure: self.onUpdateFail)

            requestCreator.request(for: .getStalls)
        }

        func requestUpdates(from date: Date) {
            let requestCreator = IrisProvider.RequestCreator(onSuccess: onUpdateRequestSuccess, onGeneralFailure: onUpdateFail)
            requestCreator.request(for: .getStallUpdates(lastUpdate: date))
        }

        func onUpdateRequestSuccess(response: Response) {
            guard let responseDict = JSONDeserializer.toDictionary(json: response.data) else {
                let response = String(data: response.data, encoding: .utf8) ?? "No response"
                log.error("Response: \(response)")

                self.onUpdateFail()
                return
            }
            
            guard let newDict = responseDict["new"] as? [[String : Any]],
                  let modifiedDict = responseDict["modified"] as? [[String : Any]],
                  let deletedDict = responseDict["deleted"] as? [Int] else {
                log.error("An error occurred casting response dictionary")
                log.error("Response Dictionary: \(responseDict)")

                self.onUpdateFail()
                return
            }
            
            guard let new = Deserializer.toStallArray(dict: newDict),
                  let modified = Deserializer.toStallArray(dict: modifiedDict) else {
                log.error("An error occurred mapping dictionaries")

                self.onUpdateFail()
                return
            }


            //Update time first
            let dateNow = Date() //Date always initializes with current date
            log.info("Updating last updated for Stalls")
            ModelType.stalls.setLastUpdated(dateNow)
            
            //Then update database
            LocalDatabase.save(stalls: new, isUpdate: false)
            LocalDatabase.save(stalls: modified, isUpdate: true)

            for id in deletedDict {
                guard let stall = LocalDatabase.getStall(id: id) else {
                    log.error("Could not find stall of id \(id)")

                    //If could not find stall, stall was probably deleted anyway
                    continue
                }

                LocalDatabase.delete(id: stall.id)
            }

            self.onUpdateFinish()
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

        static func toStall(dict: [String : Any]) -> Stall? {
            let stall = Stall(JSON: dict)

            if stall == nil {
                log.error("An error occured deserializing stall.")
                log.error("Stall Object: \(dict)")
            }

            return stall
        }

        static func toStallArray(response: Response) -> [Stall]? {
            do {
                return try response.mapArray(Stall.self)
            } catch {
                handleDeserializationError(error: error, response: response)
                return nil
            }
        }

        static func toStallArray(dict: [[String : Any]]) -> [Stall]? {
            var array = [ Stall ]()

            for stallDict in dict {
                guard let stall = toStall(dict: stallDict) else {
                    return nil
                }

                array.append(stall)
            }

            return array
        }

        static func handleDeserializationError(error: Swift.Error, response: Response? = nil) {
            log.error("An error occurred deserializing stall.")
            log.error(error.localizedDescription)

            if let response = response {
                let responseString = String(data: response.data, encoding: .utf8) ?? "No response."
                log.error("Response String: \(responseString)")
            }
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

        static func save(stall: Stall, isUpdate: Bool) {
            try! self.realm.write {
                self.realm.add(stall, update: isUpdate)
            }
        }

        static func save(stalls: [Stall], isUpdate: Bool) {
            try! self.realm.write {
                for stall in stalls {
                    self.realm.add(stall, update: isUpdate)
                }
            }
        }

        static func getStalls() -> [Stall] {
            return Array(self.realm.objects(Stall.self)).sorted {
                $0.id < $1.id
            }
        }

        static func delete(id: Int) {
            try! self.realm.write {
                let stallToDelete = self.realm.objects(Stall.self).filter("id == \(id)")
                self.realm.delete(stallToDelete)
            }
        }

    }

}
