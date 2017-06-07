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
    //Usually performed on bulk updates
    func didReceiveBulkUpdate()

    func stallIsCreated(stall: Stall)

    func stallIsModified(stall: Stall)

    func stallIsDeleted(id: Int)
}

class StallUpdateManager: WebSocketReceiver, WebSocketConnectionDelegate, AuthenticationDelegate {
    static var delegate: StallUpdateDelegate?

    //Manual HTTP Update
    //TODO: Finish completion handler
    static func manualUpdate(completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        guard let lastUpdated = ModelType.stalls.lastUpdated else {
            initializeDatabase(completion: completion)
            return
        }

        let onRequestSuccess: (Response) -> Void = { response in
            onUpdateRequestSuccess(response: response, completion: completion)
        }

        let onRequestFailure: () -> Void = {
            completion?(.failed)
        }

        log.verbose("Stalls last updated \(lastUpdated), fetching updates...")
        let requestCreator = IrisProvider.RequestCreator(onSuccess: onRequestSuccess,
                                                         onGeneralFailure: onRequestFailure)
        requestCreator.request(for: .getStallUpdates(lastUpdate: lastUpdated))
    }

    fileprivate static func renewModelUpdateDate() {
        let dateNow = Date()
        log.verbose("Renewing Last Update for Stall...")
        ModelType.stalls.setLastUpdated(dateNow)
    }


    fileprivate static func onUpdateRequestSuccess(response: Response,
                                                   completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        guard let responseDict = JSONDeserializer.toDictionary(json: response.data) else {
            let response = String(data: response.data, encoding: .utf8) ?? "No response"
            log.error("Response: \(response)")
            completion?(.failed)
            return
        }

        guard let newDict = responseDict["new"] as? [[String : Any]],
              let modifiedDict = responseDict["modified"] as? [[String : Any]],
              let deletedDict = responseDict["deleted"] as? [Int] else {
            log.error("An error occurred casting response dictionary")
            log.error("Response Dictionary: \(responseDict)")
            completion?(.failed)
            return
        }

        guard let new = StallPersistence.Deserializer.toStallArray(dict: newDict),
              let modified = StallPersistence.Deserializer.toStallArray(dict: modifiedDict) else {
            log.error("An error occurred mapping dictionaries")
            completion?(.failed)
            return
        }

        self.renewModelUpdateDate()

        //Then update database
        let updates = new + modified
        StallPersistence.LocalDatabase.save(stalls: updates)

        for id in deletedDict {
            guard let stall = StallPersistence.LocalDatabase.getStall(id: id) else {
                log.error("Could not delete stall \(id): Could not find matching ID in database")

                //If could not find stall, stall was probably deleted anyway
                continue
            }

            StallPersistence.LocalDatabase.delete(id: stall.id)
        }

        self.delegate?.didReceiveBulkUpdate()
        let hasNewData = !new.isEmpty && !modified.isEmpty
        completion?(hasNewData ? .newData : .noData)
    }

    //No history of updates? Fetch everything.
    fileprivate static func initializeDatabase(completion: ((UIBackgroundFetchResult) -> Void)? = nil) {

        let onRequestSuccess: (Response) -> Void = { response in
            guard let stalls = StallPersistence.Deserializer.toStallArray(response: response) else {
                return
            }

            StallPersistence.LocalDatabase.save(stalls: stalls)
            self.renewModelUpdateDate()
            log.info("Local database initialization complete")
            self.delegate?.didReceiveBulkUpdate()

            let hasNewStalls = !stalls.isEmpty
            completion?(hasNewStalls ? .newData : .noData)
        }

        let onRequestFailure: () -> Void = {
            completion?(.failed)
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onRequestSuccess,
                                                         onGeneralFailure: onRequestFailure)

        requestCreator.request(for: .getStalls)
    }

    //MARK: - WebSocket update handler
    fileprivate static func stallIsCreated(dict: [String : Any]) {
        guard let stall = StallPersistence.Deserializer.toStall(dict: dict) else {
            log.error("Unable to deserialize WebSocket Stall: \(dict)")
            return
        }

        StallPersistence.LocalDatabase.save(stall: stall)
        self.delegate?.stallIsCreated(stall: stall)
    }

    fileprivate static func stallIsModified(dict: [String : Any]) {
        guard let stall = StallPersistence.Deserializer.toStall(dict: dict) else {
            log.error("Unable to deserialize WebSocket Stall: \(dict)")
            return
        }

        StallPersistence.LocalDatabase.save(stall: stall)
        self.delegate?.stallIsModified(stall: stall)
    }

    fileprivate static func stallIsDeleted(id: Int) {
        StallPersistence.LocalDatabase.delete(id: id)
        self.delegate?.stallIsDeleted(id: id)
    }

    //MARK: - WebSocketReceiver
    static func handle(update: WebSocketUpdate) {
        self.renewModelUpdateDate()

        switch update {
            case .creation(let dict):
                stallIsCreated(dict: dict)
            case .modification(let dict):
                stallIsModified(dict: dict)
            case .deletion(let id):
                stallIsDeleted(id: id)
        }
    }

    //MARK: - WebSocketConnectionDelegate
    static func websocketDidConnect() {
        //What did we miss on?
        self.manualUpdate()
    }

    static func websocketDidDisconnect() {
        //Removed update, we probably won't need it
        //What can we put in didDisconnect?

    }

    //MARK: - AuthenticationDelegate
    static func onAuthenticationSuccess() {
        self.manualUpdate()
    }
}

class StallPersistence {

    static func create(stallName: String, onFailure: @escaping () -> Void) {

        let onStallCreationSuccess: (Response) -> Void = { _ in
            log.verbose("Create stall success")
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onStallCreationSuccess,
                                                         onGeneralFailure: onFailure)

        requestCreator.request(for: .createStall(stallName: stallName))
    }

    static func modify(newStall new: Stall, onFailure: @escaping () -> Void) {

        let onResponse: (Response) -> Void = { _ in
            log.verbose("Edit stall success")
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onResponse, onGeneralFailure: onFailure)

        requestCreator.request(for: .modifyStall(stall: new))
    }

    static func delete(id: Int, onFailure: @escaping () -> Void) {

        let onSuccess: (Response) -> Void = { _ in
            log.verbose("Delete stall success")
        }

        let requestCreator = IrisProvider.RequestCreator(onSuccess: onSuccess, onGeneralFailure: onFailure)

        requestCreator.request(for: .deleteStall(id: id))
    }

    static func getAllStalls() -> [Stall] {
        return LocalDatabase.getStalls()
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

        static func save(stall: Stall) {
            let exists = getStall(id: stall.id) != nil //The stall exists
            try! self.realm.write {
                self.realm.add(stall, update: exists)
            }
        }

        static func save(stalls: [Stall]) {
            stalls.forEach { stall in
                self.save(stall: stall)
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
