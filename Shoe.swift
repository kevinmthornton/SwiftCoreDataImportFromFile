//
//  Shoe.swift
//  SwiftCoreDataImportFromFile
//
//  Created by kevin thornton on 11/3/14.
//  Copyright (c) 2014 PCC. All rights reserved.
//

import Foundation
import CoreData

class Shoe: NSManagedObject {

    @NSManaged var shoeType: String
    @NSManaged var shoePrice: NSNumber
    @NSManaged var shoeDesc: String
    @NSManaged var shoeName: String
    @NSManaged var gender: Gender

}
