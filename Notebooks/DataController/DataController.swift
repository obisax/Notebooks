//
//  DataController.swift
//  Notebooks
//
//  Created by Franco Paredes on 28/01/21.
//

import Foundation
import CoreData
import UIKit

class DataController:NSObject{
    private let persistentContainer:NSPersistentContainer
    
    var viewContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    // Multi- threading y porque?
    // podemos saber de datos antes que el usuario lo pida
    // nos permite ejecutar codigo en paralelo
    // no nos vamos a enfocar en performance pero en predecir lo que el usuario quiera
    // la UI o main necesita un "view" o "main" context que viva tambien en el main thread pero
    // que tambien sea nuestro source of truth
    // tipos de managedObjectContext NSMainQueueConcurrencyType : se utiliza para identificar managedobjectcontext o maincontent donde se va a visualizar las vistas , visualizar vistas vs NSPrivateQueueConcurrencyType: busca datos en background o carga o leer  datos
    // serial queues vs concurrency queues
    // serial queues nos permite ejecutar las tareas que le indiquemos al queue en orden
    // concurrency van ejecutar las tareas de manera concurrente o en paralelo mientras vayan siendo
    // registradas en nuestro queue
    
    // 1. existen 2 tipos managedObjectContext
    // 2. vamos a utilizar el NSPrivateQueueConcurrencyType para crear managedObjectContext privados o que existen en background, para cargar y hacer modificaciones de nuestros datos
    // 3. vamos a utilizar un viewContext para presentar los datos del managedObjectContext privado o que existen en el background
    
    
    
    @discardableResult
    //Nos permite crear un coredata Stack
    init(modelName:String, optionalStoreName:String?, completionHandler: (@escaping (NSPersistentContainer?) -> ())){
        
        if let optionalStoreName = optionalStoreName {
            let managedObjectModel = Self.manageObjectModel(with: modelName)
            self.persistentContainer = NSPersistentContainer(name: optionalStoreName,
                                                             managedObjectModel: managedObjectModel)
            
            super.init()
            
            persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }
                    completionHandler(self?.persistentContainer)
                
            }
            persistentContainer.performBackgroundTask{ (privateMOC) in
                //toda la carga y modificaciones de nuestro grafo de objetos
                //luego cuando terminemos le decimos al privateMOC.save()
                //el privateMOC va a estar conectado con un viewContext
                //el viewContext va actualizar con los datos que esten dentro de nuestro privateMOC
            
            }
            
        }else {
              self.persistentContainer = NSPersistentContainer(name: modelName)
              
              super.init()
        //dame un ilo en esto en background que se ejecute de manera asincrona
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            //una vez que cargue las store
            self?.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    completionHandler(self?.persistentContainer)
                }
            }
        }
             
    }
    
}
    
    func fetchNotebooks(using fetchRequest:NSFetchRequest<NSFetchRequestResult>)-> [NotebookMO]?{
        do{
            return try persistentContainer.viewContext.fetch(fetchRequest) as? [NotebookMO]
        }catch{
            fatalError("Failure to fetch notebooks with context: \(fetchRequest), \(error)")
        }
    }
    
    func fetchNotes(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [NoteMO]? {
    do{
        return try viewContext.fetch(fetchRequest) as? [NoteMO]
    }catch{
    fatalError("Failure to fetch Notes")
    }
    
    }
    
    func save(){
        do{
        try persistentContainer.viewContext.save()
        } catch {
            print("=== could not save view context ===")
            print( "error: \(error.localizedDescription)" )
            }
        }
    
    func reset(){
        persistentContainer.viewContext.reset()
    }
    
    func delete(){
        guard let persistentStoreUrl = persistentContainer
                .persistentStoreCoordinator.persistentStores.first?.url else {
            return
        }
        
        do{
            try persistentContainer.persistentStoreCoordinator
                                   .destroyPersistentStore(at: persistentStoreUrl,
                                        ofType: NSSQLiteStoreType,
                                        options: nil)
        }catch{
            fatalError("could not delete test database. \(error.localizedDescription)")
        }
    }
    
    //funcion que crea managedObjectModel
    static func manageObjectModel(with name:String) -> NSManagedObjectModel{
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else{
            fatalError("Error could not find model")
        }
        guard  let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managedObjectModel")
        }
        return managedObjectModel
    }
    //Datos in background
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void){
        //creamos nuestro managedObjectContext privado
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        //seteamos nuestro viewContext
        privateMOC.parent = viewContext
        //ejecutamos el block dentro de este privadoMOC
        privateMOC.perform{
            block(privateMOC)
        }
    }
}

extension DataController{
    
    func loadNotesInBackground(){
        performInBackground { (privateManagedObjectContext) in
        let managedObjectContext = privateManagedObjectContext
        guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook con Notas",
                                  in: managedObjectContext) else {
            return
        }
        NoteMO.createNote(managedObjectContext: managedObjectContext ,
            notebook: notebook,
            title: "nota 1",
            content:  "contenido de note",
            createdAt: Date())
        NoteMO.createNote(managedObjectContext: managedObjectContext ,
            notebook: notebook,
            title: "nota 2",
            content:  "contenido de note",
            createdAt: Date())
        NoteMO.createNote(managedObjectContext: managedObjectContext ,
            notebook: notebook,
            title: "nota 3",
            content:  "contenido de note",
            createdAt: Date())
        
        let notebookImage = UIImage(named: "notebookImage")
        if  let dataNotebookImage = notebookImage?.pngData(){
            let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                      managedObjectContext: managedObjectContext)
            
            notebook.photograph = photograph
            
        }
            do{
            try managedObjectContext.save()
            }catch{
                fatalError("Failure to save in background")
            }
            
        }
        
}
    
    func loadNotesIntoViewContext(){
        
    //Ambas opciones son hacen el mismo llamado
    //let managedObjectContext = persistentContainer.viewContext
   
    let managedObjectContext = viewContext
    guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                              title: "notebook con Notas",
                              in: managedObjectContext) else {
        return
    }
    NoteMO.createNote(managedObjectContext: managedObjectContext ,
        notebook: notebook,
        title: "nota 1",
        content: "contenido de note",
        createdAt: Date())
    NoteMO.createNote(managedObjectContext: managedObjectContext ,
        notebook: notebook,
        title: "nota 2",
        content: "contenido de note",
        createdAt: Date())
    NoteMO.createNote(managedObjectContext: managedObjectContext ,
        notebook: notebook,
        title: "nota 3",
        content: "contenido de note",
        createdAt: Date())
    
    let notebookImage = UIImage(named: "notebookImage")
    if  let dataNotebookImage = notebookImage?.pngData(){
        let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                  managedObjectContext: managedObjectContext)
        
        notebook.photograph = photograph
        
    }
        do{
        try managedObjectContext.save()
        }catch{
            fatalError("Failure to save in background")
        }
}

    func loadNotebooksIntoViewContext(){
        
        let managedObjectContext = viewContext
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook1",
                                  in: managedObjectContext)
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook2",
                                  in: managedObjectContext)
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook3",
                                  in: managedObjectContext)
    }
    
    func addNote(with urlImage: URL, notebook: NotebookMO) {
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }
            
            // nsmanagedobjects representan un registro en nuestro persistent store.
            // utilizando el object id del objeto nuestro managedObjectContext puede recrear
            // el objeto en su grafo
            let notebookID = notebook.objectID
            let copyNotebook = managedObjectContext.object(with: notebookID) as! NotebookMO
            
            let photograhMO = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext)
            
            let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                         notebook: copyNotebook,
                                         title: "titulo de nota",
                                         content : "Contents",
                                         createdAt: Date())
            
            photograhMO.note = note
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }
    
    func addPhotographs(with urlImage: URL, note: NoteMO){
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }

            let noteID = note.objectID
            let copyNote = managedObjectContext.object(with: noteID) as! NoteMO
            let photograh = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext)
            photograh.note = copyNote

            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }
    
    func detailNote(note: NoteMO, title:String, content:String){
        performInBackground{ (managedObjectContext) in
            let noteID = note.objectID
            let copyNote = managedObjectContext.object(with: noteID) as! NoteMO
            
            copyNote.title = title
            copyNote.contents = content
            do{
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
            self.save()
        }
    
    }
    
    
}
