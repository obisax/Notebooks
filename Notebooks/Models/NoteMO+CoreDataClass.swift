//
//  NoteMO+CoreDataClass.swift
//  Notebooks
//
//  Created by Franco Paredes on 7/02/21.
//
//

import Foundation
import CoreData

@objc(NoteMO)
public class NoteMO: NSManagedObject {
    @discardableResult
    static func createNote(managedObjectContext:NSManagedObjectContext,
                           notebook:NotebookMO,
                           title:String,
                           content: String,
                           createdAt: Date) -> NoteMO?{
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: managedObjectContext) as? NoteMO
        
        note?.title = title
        note?.contents = content
        note?.createdAt = createdAt
        note?.notebook = notebook
        
       
        return note
    }

}
