//
//  PhotographMO+CoreDataClass.swift
//  Notebooks
//
//  Created by Franco Paredes on 14/02/21.
//
//

import Foundation
import CoreData

@objc(PhotographMO)
public class PhotographMO: NSManagedObject {
    
    static func createPhoto(imageData: Data,
                            managedObjectContext: NSManagedObjectContext) -> PhotographMO {
        let photograph = NSEntityDescription.insertNewObject(forEntityName: "Photograph",
                                                             into: managedObjectContext) as? PhotographMO
        photograph?.imageData = imageData
        photograph?.createdAt = Date()
        
        return photograph!
        
    }

}
