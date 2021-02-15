//
//  NotebookMO.swift
//  Notebooks
//
//  Created by Franco Paredes on 28/01/21.
//

import Foundation
import CoreData


public class NotebookMO: NSManagedObject{
    
    //Funcion para avisar cuando se cree un notebook
    //no usar init(){}
    //no usar deinit(){}
    //uniquing: todos los managed Object representan a un solo registro en nuestro persistentStore
    //fault: representan objectos que referencian a registros en nuestro persistentStore,
    //pero no cargados en memoria 
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        print("se creo un notebook.")
    }
    
    public override func didTurnIntoFault() {
        super.didTurnIntoFault()
        print("Se creo un fault")
    }
    
    
    @discardableResult
    static func createNotebook(createdAt: Date,
                               title: String,
                               in managedObjectContext: NSManagedObjectContext) -> NotebookMO? {
        let notebook = NSEntityDescription.insertNewObject(forEntityName: "Notebook",
                                                           into: managedObjectContext) as? NotebookMO
        
        notebook?.createdAt = createdAt
        notebook?.title = title
    
        
        return notebook
        
    }
}
