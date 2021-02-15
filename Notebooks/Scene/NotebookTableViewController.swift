//
//  NotebookTableViewController.swift
//  Notebooks
//
//  Created by Franco Paredes on 31/01/21.
//

import UIKit
import CoreData

class NotebookTableViewController: UITableViewController {
    
    var dataController : DataController?
    var fetchResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    
    //Parametrizacion del dataController para usarlo con el test
    public convenience init (dataController: DataController){
        self.init()
        self.dataController = dataController
    }
    
    func initializeFetchResultsController(){
        guard let dataController = dataController else { return }
        let viewContext = dataController.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebookTitleSortDescriptor = NSSortDescriptor(key: "title",
                                                           ascending: true)
        
        request.sortDescriptors = [notebookTitleSortDescriptor]
        //Verificacion de cuantos objectos y cambios hay
        self.fetchResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                 managedObjectContext: viewContext,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        self.fetchResultsController?.delegate = self
        
        do{
        try self.fetchResultsController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook fetch.")
        }
    }
    
    init(){
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
     initializeFetchResultsController()
        // crear un boton en el nav item para cargar data
            // crear un barbutton item.
            // setar su funcionalidad
            // colocarlo en nuestro nav item.
            // y llamar a nuestro data controller para poder cargar data.
        let loadDataBarbuttonItem = UIBarButtonItem(title: "Load",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(loadData))
        
        let saveDataBarbuttonItem = UIBarButtonItem(title: "Save",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(save))
            
        // crear un boton en el nav item para borrar data.
            // crear un barbutton item.
            // setar su funcionalidad
            // colocarlo en nuestro nav item.
            // y llamar a nuestro data controller para poder borrar data.
        let deleteBarButtonItem = UIBarButtonItem(title: "Delete",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(deleteData))
        
        let resetBarButtonItem = UIBarButtonItem(title: "Reset",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(reset))
        
        navigationItem.leftBarButtonItems = [deleteBarButtonItem, resetBarButtonItem]
        navigationItem.rightBarButtonItems = [loadDataBarbuttonItem, saveDataBarbuttonItem]
        
    }
    
    @objc
    func deleteData() {
        dataController?.save()
        dataController?.delete()
        dataController?.reset()
        initializeFetchResultsController()
        tableView.reloadData()
    }
    
    @objc
    func loadData() {
        dataController?.loadNotesInBackground()
    }
    
    @objc
    func save() {
        dataController?.save()
    }
    
    @objc
    func reset() {
        dataController?.reset()
        initializeFetchResultsController()
        tableView.reloadData()
    }
    
    
    //devuelve el numero de las secciones
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController{
            return fetchResultsController.sections![section].numberOfObjects
        }else {
            return 0
        }
    }
    
    //Configuracion de celdas
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "notebookCell",
                                                 for: indexPath)
        
        guard let notebook = fetchResultsController?.object(at: indexPath) as? NotebookMO else{
            
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.textLabel?.text = notebook.title
        
        if let createdAt = notebook.createdAt{
            cell.detailTextLabel?.text = HelperDateFormatter.textFrom(date: createdAt)
        }
        if let photograph = notebook.photograph,
           let imageData = photograph.imageData,
           let image = UIImage(data: imageData){
            cell.imageView?.image = image
        }
        
        return cell
        }
    
    //MARK: - NAVIGATION
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier,
           segueId == "noteSegueIdentifier"{
            //encontrar o castear el notetableviewcontroller
            let destination = segue.destination as! NoteTableViewController
            //tenemos que encontrar el notebook que elegimos
            let indexPathSelected = tableView.indexPathForSelectedRow!
            let selectedNotebook = fetchResultsController?.object(at: indexPathSelected) as! NotebookMO
            //luego setear el notebook
            destination.notebook = selectedNotebook
            //luego setear el datacontroller
            destination.dataController = dataController
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteSegueIdentifier", sender: nil)
    }
}


//MARK: -  NSFetchedResultsControllerDelegate

extension NotebookTableViewController :  NSFetchedResultsControllerDelegate{
    
    //will change
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    //did change a section
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)  {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move, .update:
            break
        @unknown default: fatalError()
        }
    }
    //did change an object
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default: fatalError()
        }
    }
    //did change content ,comiteamos los cambios
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
