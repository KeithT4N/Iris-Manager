//
// Created by Keith Tan on 5/10/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Moya
import ObjectMapper
import Moya_ObjectMapper
import RealmSwift

class ProductEntityRetriever {

    static let shared = ProductEntityRetriever()
    let realm = try! Realm()
    fileprivate init() {
    }

    func updateLocalDatabase() {
        print("Retrieving product updates...")
        request(for: .getProductUpdates) { response in
            do {
                let productUpdates = try response.mapArray(ProductUpdateSkeleton.self)
                print("Success")
                self.fetchNewUpdates(newUpdateSkeletons: productUpdates)
            } catch {
                //TODO: Failure case
            }
        }
    }

    fileprivate func fetchNewUpdates(newUpdateSkeletons: [ProductUpdateSkeleton]) {
        let currentProducts = realm.objects(Product.self)

        var productsToUpdate: [Int] = []
        var productsToAdd:    [Int] = []

        for updateSkeleton in newUpdateSkeletons {
            guard let index = currentProducts.index(where: { $0.id == updateSkeleton.id }) else {
                productsToAdd.append(updateSkeleton.id) //Product must be new
                return
            }

            let currentProduct = currentProducts[index]

            if currentProduct.lastUpdated < updateSkeleton.lastUpdated {
                productsToUpdate.append(updateSkeleton.id) //Product must be outdated
            }
        }

        print("Products to update: \(productsToUpdate)")
        print("Products to add: \(productsToAdd)")

        productsToUpdate.forEach { id in
            getProduct(id: id, isUpdate: true)
        }

        productsToAdd.forEach { id in
            getProduct(id: id, isUpdate: false)
        }
    }

    fileprivate func getProduct(id: Int, isUpdate: Bool) {
        request(for: .getProduct(productID: id)) { response in
            do {
                let product = try response.mapObject(Product.self)

                try! self.realm.write {
                    self.realm.add(product, update: isUpdate)
                }
            } catch {
                print("An error occurred mapping json to Product Object")
                print(error.localizedDescription)
                print("Response Code: \(response.statusCode)")
                print("Response JSON: \(String(data: response.data, encoding: .utf8) ?? "No data")")
            }
        }
    }
}
