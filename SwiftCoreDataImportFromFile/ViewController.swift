//
//  ViewController.swift
//  SwiftCoreDataImportFromFile
//
//  Created by kevin thornton on 10/27/14.
//  Copyright (c) 2014 PCC. All rights reserved.
//

import UIKit
import CoreData

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)!.doubleValue
    }
}


class ViewController: UIViewController {
    var appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var moc = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // do we have data in the database? if so, show it; if not, enter it
        let fetchRequest = NSFetchRequest(entityName: "Gender")
        let sort = NSSortDescriptor(key: "type", ascending: true)
        // should do a predicate here
        fetchRequest.sortDescriptors = [sort]
        let results = moc.executeFetchRequest(fetchRequest, error: nil)
        
        // delete everything if needs be
//        deleteAllFromCoreData()
        
        if results?.count > 0 {
            println("data is present")
            showDataInCoreData()
        } else {
            println("no data, start import")
            // start JSON import
            importFromJSON()
            
        } // else results
    } // VDL

    // MARK: Core Data
    func enterArrayIntoCoreData(passedGender: String, passedArray: Array<Array<String>> ){
//        println(passedArray[0][0])
        // passedArray[0][0] - shoeName ; passedArray[0][1] - shoeType; passedArray[0][2] - shoePrice
        
        // get the top gender entity; this will have a shoe to-many relationship
        let genderEntity = NSEntityDescription.entityForName("Gender", inManagedObjectContext: moc)
        // get gender object
        let genderObj = Gender(entity:genderEntity!, insertIntoManagedObjectContext: moc)
        genderObj.type = passedGender
        
        // save gender
         appDelegate.saveContext()
        
        // get gender object for relationship by setting up a predicate with the passedGender as the search in type
        let genderFetchRequest = NSFetchRequest(entityName: "Gender")
        let genderSort = NSSortDescriptor(key: "type", ascending: true)
        // PREDICATE
        genderFetchRequest.predicate = NSPredicate(format: "type = %@", passedGender)
        
        genderFetchRequest.sortDescriptors = [genderSort]
        let genderResults = moc.executeFetchRequest(genderFetchRequest, error: nil)
        // do we have this gender object? if so, continue on and create shoes with a reltionship to it
        if genderResults?.count > 0 {
            let genderFromCoreData = genderResults![0] as Gender
            println("genderFromCoreData: \(genderFromCoreData.type)")
            // get shoe entity
            let shoeEntity = NSEntityDescription.entityForName("Shoe", inManagedObjectContext: moc)
            // iterate over the passed array getting a new shoe object, incrementing array, setting values and saving
            
            for(var arrayCounter = 0; arrayCounter < passedArray.count; arrayCounter++) {
                let shoeObj = Shoe(entity:shoeEntity!, insertIntoManagedObjectContext: moc)
                // add shoe data
                shoeObj.shoeName = passedArray[arrayCounter][0]
                shoeObj.shoeType = passedArray[arrayCounter][1]
                // toDouble is a String extension from above to convert a String to a Double and explicitly unwrap it
                shoeObj.shoePrice = passedArray[arrayCounter][2].toDouble()!
                // enter shoes and gender relationship
                shoeObj.gender = genderFromCoreData
                // save shoes
                appDelegate.saveContext()
                println("Entered shoe: \(passedArray[arrayCounter][0]) with gender \(genderFromCoreData.type)")
            }
        } else {
            println("ERROR: no genderType: \(passedGender)")
            // TODO: exit out of this function and return error msg?
        }
    } // enterArrayIntoCoreData
    
    func enterNSArrayIntoCoreData(gender: String, passedArray: NSArray ){
        println(passedArray)
    }
    
    
    func showDataInCoreData() {
        println("showDataInCoreData")

        // get the top gender entity; this will have a shoe to-many relationship
        let genderEntity = NSEntityDescription.entityForName("Gender", inManagedObjectContext: moc)
        // get gender object for relationship by setting up a predicate with the passedGender as the search in type
        let genderFetchRequest = NSFetchRequest(entityName: "Gender")
        let genderSort = NSSortDescriptor(key: "type", ascending: true)
        genderFetchRequest.sortDescriptors = [genderSort]
        let genderResults = moc.executeFetchRequest(genderFetchRequest, error: nil)
        // do we have this gender object? if so, continue on and create shoes with a reltionship to it
        if genderResults?.count > 0 {
            // shoe set up
            let shoeEntity = NSEntityDescription.entityForName("Shoe", inManagedObjectContext: moc)
            let shoeFetchRequest = NSFetchRequest(entityName: "Shoe")
            let shoeSort = NSSortDescriptor(key: "name", ascending: true)
            
            // iterate over all the genders in CD and get the shoe's related to the gender
            // need the [Gender] or you get the error "does not conform to protocol sequence"
            for gender in genderResults! as [Gender] {
                println("gender is: \(gender.type)")
//                shoeFetchRequest.predicate = NSPredicate(format: "gender LIKE 'Mens'")
                let shoeResults = moc.executeFetchRequest(shoeFetchRequest, error: nil)
                if shoeResults?.count > 0 {
                    for shoe in shoeResults as [Shoe] {
                        println("name: \(shoe.shoeName) | gender: \(shoe.gender)")
                    }
                } else {
                    println("no shoes for \(gender.type)")
                }
                
            }
        }
    } // showDataInCoreData
    
    // clear out all data from CD
    func deleteAllFromCoreData() {
        // delete all genders
        let genderFetchRequest = NSFetchRequest(entityName: "Gender")
        let genderSort = NSSortDescriptor(key: "type", ascending: true)
        // should do a predicate here
        genderFetchRequest.sortDescriptors = [genderSort]
        let genderResults = moc.executeFetchRequest(genderFetchRequest, error: nil)
        let genderFromCoreData = genderResults![0] as Gender
        println("deleting from Gender CD: \(genderFromCoreData.type)")
        moc.deleteObject(genderFromCoreData)
        
        // delete all shoes
        let shoeFetchRequest = NSFetchRequest(entityName: "Shoe")
        let shoeSort = NSSortDescriptor(key: "name", ascending: true)
        let shoeResults = moc.executeFetchRequest(shoeFetchRequest, error: nil)
        for shoe:AnyObject in shoeResults! {
            println("deleting shoe: \(shoe)")
            moc.deleteObject(shoe as NSManagedObject)
        }
        
        appDelegate.saveContext()
    }
    
    // MARK: JSON 
    // import from JSON
    func importFromJSON() {
        // which type are we importing? Mens, Womens, Childrens etc...
        let gengerType = "Mens" // TODO: should be array
        // read file
        let bundle = NSBundle.mainBundle()
        let filePath = bundle.pathForResource(gengerType, ofType: "json")
        var error:NSError?
        //reading
        let jsonFileContents = NSData(contentsOfFile: filePath!, options: nil, error: &error)
        if let theError = error {
            print("\(theError.localizedDescription)")
        } else {
            // format the data that was passed in
            var formattedArray = formatJsonData(jsonFileContents!)
            var formattedNSArray = formatJsonDataFoundation(jsonFileContents!)
            
            // println(formattedArray)
            // pass in the array to enter it in Core Data
            enterArrayIntoCoreData(gengerType, passedArray: formattedArray)
//            enterNSArrayIntoCoreData(gengerType, passedArray: formattedNSArray)
            
        } // else
    }
    
    
    // NSArray’s are immutable, so you can’t add to them. You either have to make formattedJsonArray a mutable array
    // (and use the Foundation methods to add objects to it), or make it a Swift array from the start, and use .append()
    
    // return a Swift Array of Arrays that contain strings: Array<Array<String>>
    // use shortcut notation of [[String]] to represent  Array<Array<String>>
    func formatJsonData(passedJsonData: NSData) -> Array<Array<String>> {
        var jsonData     = NSJSONSerialization.JSONObjectWithData(passedJsonData, options: .MutableContainers, error: nil) as NSDictionary
        // start a blank array of array of strings
        var formattedJsonArray = Array<Array<String>>()
        
        // comes in as an NSArray from the NSJSONSerialization call
        for shoeValue in jsonData["shoeList"] as NSArray {
            // if shoeName is there, the rest are as well so don't need to cast as optional
            if let shoeName = shoeValue["shoeName"] as? String {
                let shoeType = shoeValue["shoeType"] as String
                let shoePrice = shoeValue["price"] as String
                formattedJsonArray.append([shoeName, shoeType, shoePrice])
            } // if
        } // for
        
        return formattedJsonArray
    }
    
    func formatJsonDataFoundation(passedJsonData: NSData) -> NSArray {
        var jsonData     = NSJSONSerialization.JSONObjectWithData(passedJsonData, options: .MutableContainers, error: nil) as NSDictionary
        // start a blank array of array of strings
        var formattedJsonArray:NSMutableArray = []
        
        // comes in as an NSArray from the NSJSONSerialization call
        for shoeValue in jsonData["shoeList"] as NSArray {
            // if shoeName is there, the rest are as well so don't need to cast as optional
            if let shoeName = shoeValue["shoeName"] as? String {
                let shoeType = shoeValue["shoeType"] as String
                let shoePrice = shoeValue["price"] as String
                formattedJsonArray.addObject([shoeName, shoeType, shoePrice])
            } // if
        } // for
        
        return formattedJsonArray
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

