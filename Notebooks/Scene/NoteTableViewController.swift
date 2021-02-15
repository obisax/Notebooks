//
//  NoteTableViewController.swift
//  Notebooks
//
//  Created by Franco Paredes on 13/02/21.
//

import UIKit
import CoreData

class NoteTableViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var dataController : DataController?
    var fetchResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    
    var notebook: NotebookMO?
    
    public convenience init( dataController: DataController){
        self.init()
        self.dataController = dataController
    }
    
    func initializeFetchResultsController(){
        //1.declara nuestro datacontroller
        guard let dataController = dataController ,
            let notebook = notebook else{
                return
        }
        //2. crear nuestro NsFetchRequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        //3.seteamos el NSSortDescription
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreatedAtSortDescriptor]
        //4. creamos nuestro NSPredicate
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)
        // 1. No se puede colocar queries que son de sql nativo dentro de los predicate
        //2.solo se pueden hacer queries de uno a muchos elementos dentro de nuestro key path/format en un NSPredicate
        //3. No se pueden hacer sort descriptor con properties que son transients
        
        //4.creamos el NSfetchResultcontroller
        let managedObjectContext = dataController.viewContext
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController?.delegate = self
        //5. perform fetch
        do{
        try fetchResultsController?.performFetch()
        }catch {
            fatalError("couldn't find notes \(error.localizedDescription)")
        }
    }
    init(){
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder){
        super.init(coder: coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        initializeFetchResultsController()
        //crear un boton que abra el image picker y cuando se elija una imagen,se pueda agregar una nota con la imagen
        setupNavigationItem()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier,
           segueId == "detailnoteseguev"{
            let destination = segue.destination as! DetailNoteViewController
            let indexPathSelected = tableView.indexPathForSelectedRow!
            let selectedNote = fetchResultsController?.object(at: indexPathSelected) as! NoteMO
            destination.note = selectedNote
            destination.dataController = dataController
        }
    }
    func setupNavigationItem(){
        //crear un boton (uibarbutton)
        let addNoteBarButtonItem = UIBarButtonItem(title: "Add Note",
                                                   style: .done,
                                                   target: self,
                                                   action:#selector(createAndPresentImagePicker))
        //setear ese boton con un metodo que pueda abrir el image picker
        
        navigationItem.rightBarButtonItem = addNoteBarButtonItem
    }
    
    @objc
    func createAndPresentImagePicker(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
           let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary){
            picker.mediaTypes = availableTypes
        }
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true){[unowned self] in
            if let urlImage = info[.imageURL] as? URL{
                    
                //datacontroller para poder crear nuestra nota y asociar un photograph
                if let notebook = self.notebook{
                    self.dataController?.addNote(with: urlImage, notebook: notebook)
                  
                }
            }
        }
    }
  
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCellIdentifier",
                                                 for: indexPath)
        
        guard let note = fetchResultsController?.object(at: indexPath) as? NoteMO else{
            
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.textLabel?.text = note.title
        cell.detailTextLabel?.text = note.contents
        cell.detailTextLabel?.textColor = .gray
        
       
        if note.photograph?.allObjects.count ?? 0 > 0 ,
           let photograph = note.photograph?.allObjects[0] as? PhotographMO,// relación a Photograph
           let imageData = photograph.imageData, // el atributo image data (donde posee la info de la imagen)
           let image = UIImage(data: imageData) { // aca creamos el uiimage necesario para nuestra celda.
            cell.imageView?.image = image // aca seteamos la uiimage del uiimageview en nuestra celda.
           }else {
            cell.imageView?.image = nil
           }
        cell.selectionStyle = .none
        return cell
        }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "detailnotesegue", sender: nil)
    }
    


}

//MARK: -  NSFetchedResultsControllerDelegate

extension NoteTableViewController :  NSFetchedResultsControllerDelegate{
    
    //will change
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }    //did change a section
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
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
            @unknown default:
                fatalError()
        }
    }
    //did change content ,comiteamos los cambios
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

