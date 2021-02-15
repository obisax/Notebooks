//
//  NotebooksTests.swift
//  NotebooksTests
//
//  Created by Franco Paredes on 28/01/21.
//

import XCTest
import CoreData

@testable import Notebooks

class NotebooksTests: XCTestCase {
    
    private let modelName = "NotebooksModel"
    private let optionalStoreName = "NotebooksTest"
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName){ _ in}
        dataController.delete()
    }

    func testInit_DataController_Initializes(){
        DataController(modelName: modelName, optionalStoreName: optionalStoreName){_ in
            XCTAssert(true)
        }
    }
    
    //Inicia un notebook
    func testInit_Notebook(){
        DataController(modelName: modelName, optionalStoreName: optionalStoreName){(persistentContainer) in
            guard let persistentContainer = persistentContainer else {
                XCTFail()
                return
            }
            let managedObjectContext = persistentContainer.viewContext
            
            let notebook1 = NotebookMO.createNotebook(createdAt: Date(),
                                                     title: "notebook1",
                                                     in: managedObjectContext)
            XCTAssertNotNil(notebook1)
        }
    }
    //Busca un notebook
    
    func testFetch_DataController_FetchesANotebook(){
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName){ (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        dataController.loadNotebooksIntoViewContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 3)
    }
    
    
    func testFilter_dataController_FilterNotebooks(){
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        
        dataController.loadNotebooksIntoViewContext()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        
        fetchRequest.predicate = NSPredicate(format: "title == %@", "notebook1")
        
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 1)
    }
    
    func testSave_DataController_SaveInPersistentStore(){
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName){ (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        //carga datos
        dataController.loadNotebooksIntoViewContext()
       // Second Step Salvar datos del managedObjectContext
        dataController.save()
      // third step  RESET OR CLEAN UP VIEW CONTEXT managedObjectContext
        dataController.reset()
     // Buscar datos
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 3)
        
    }
    
    func testDelete_DataController_DeletesDataInPersistentStore(){
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName){ (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        //carga datos
        dataController.loadNotebooksIntoViewContext()
        // Second Step Salvar datos del managedObjectContext
        dataController.save()
        // third step  RESET OR CLEAN UP VIEW CONTEXT managedObjectContext
        dataController.reset()
        // borramos la base de datos
        dataController.delete()
        // Buscar datos
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 0)
        
    }
}

