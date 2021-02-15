//
//  NotesTests.swift
//  NotebooksTests
//
//  Created by Franco Paredes on 8/02/21.
//

import XCTest
import CoreData
//importacion del proyecto
@testable import Notebooks

class NotesTests: XCTestCase {
    private let modelName = "NotebooksModel"
    private let optionalStoreName = "NotebooksModelTest"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.


    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let dataController = DataController(modelName: modelName, optionalStoreName:  optionalStoreName  ){ _ in}
        dataController.delete()
    }

    func testCreateAndSearchNote() throws {
        let expactation = XCTestExpectation(description: "datacontrollerInBackground")
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("Do test in background")
            
            DispatchQueue.main.async {
                let dataController = DataController(modelName: self.modelName, optionalStoreName: self.optionalStoreName) {(_) in}
                // insert  notes
                dataController.loadNotesIntoViewContext()
                // salvar notes del managedObjectContext
                dataController.save()
                //reset and clean up managedObjectContext
                dataController.reset()
                //buscar notes
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                let notes =  dataController.fetchNotes(using: fetchRequest)
                
                XCTAssertEqual(notes?.count, 3)
                    expactation.fulfill()
            }
        
      
        }
        wait(for: [expactation], timeout: 2)
    }
    
    func testNoteViewController(){
        //instanciar nuestro DataController
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        let managedObjectContext = dataController.viewContext
        
        let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                 title: "notebook1", in: managedObjectContext)
        
        let note = NoteMO.createNote(managedObjectContext: managedObjectContext ,
                                     notebook: notebook!,
                                     title: "note1",
                                     createdAt: Date())
        //crearun un note viewcontroller
        let noteViewController = NoteTableViewController(dataController: dataController)
        noteViewController.notebook = notebook
        
        noteViewController.loadViewIfNeeded()
        //insertar notesdentro de nuestro object context
        let notes = noteViewController.fetchResultsController?.fetchedObjects as? [NoteMO]
        guard let noteFirstFound = notes?.first else{
            XCTFail()
            return
        }
     
        //compara el numero de objectos dentro de un fetchresultcontroller
        XCTAssertEqual(notes?.count, 1)
        XCTAssertEqual(note, noteFirstFound )
    }
    


}
