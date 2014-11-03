//
//  Gender.swift
//  SwiftCoreDataImportFromFile
//
//  Created by kevin thornton on 11/3/14.
//  Copyright (c) 2014 PCC. All rights reserved.
//

import Foundation
import CoreData

class Gender: NSManagedObject {

    @NSManaged var type: String
    @NSManaged var shoes: NSSet

}
