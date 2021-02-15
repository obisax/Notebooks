//
//  ViewController.swift
//  Notebooks
//
//  Created by Franco Paredes on 28/01/21.
//

import UIKit
import CoreData

class DetailNoteViewController: UIViewController {
    
    var blockOperations: [BlockOperation] = []
  
    @IBOutlet var noteTitleTextField: UITextField?
    @IBOutlet var noteContentTextView: UITextView?
    @IBOutlet var imageCollectionView: UICollectionView?
    
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private let pickerImageController = UIImagePickerController()
    
    var dataController : DataController?
    var fetchResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    var note: NoteMO?
    
    
    
    func initializeFetchResultsController(){
        
        guard let dataController = dataController ,
            let note = note else{
                return
        }
      
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        
        let imageCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [imageCreatedAtSortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "note == %@", note)
    
        let managedObjectContext = dataController.viewContext
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController?.delegate = self
        
        do{
        try fetchResultsController?.performFetch()
        }catch {
            fatalError("couldn't find notes \(error.localizedDescription)")
        }
    }
    
      deinit {
        for operation in blockOperations { operation.cancel() }
        blockOperations.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        
        let addImageBarbuttonItem = UIBarButtonItem(title: "Add Image",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(addImage))
        
        navigationItem.rightBarButtonItem = addImageBarbuttonItem
        
        guard note != nil else { return }
        noteTitleTextField?.text = note?.title
        noteContentTextView?.text = note?.contents
        initializeFetchResultsController()
        
   
        
        collectionViewLayout.scrollDirection = .vertical
        imageCollectionView?.collectionViewLayout = collectionViewLayout
        imageCollectionView?.dataSource = self
        imageCollectionView?.delegate = self

    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let dataController = dataController,
              let note = note else { return }
        guard let titleNote = noteTitleTextField?.text else { return }
        guard let contentNote = noteContentTextView?.text else { return }
        dataController.detailNote(note: note, title: titleNote, content: contentNote)
    }
    
    @objc func addImage(_ sender: UIButton) {
        pickerImageController.delegate = self
        pickerImageController.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
           let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary){
            pickerImageController.mediaTypes = availableTypes
        }
        present(pickerImageController, animated: true, completion: nil)
    }
}

struct helperSize {
    static let numberofCellsRow : CGFloat = 3
    static let rowSpacing: CGFloat = 8
}
extension DetailNoteViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width/helperSize.numberofCellsRow) -
            helperSize.rowSpacing
        let height = width
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return helperSize.rowSpacing
    }
    
    
}
extension DetailNoteViewController:  UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                if let note = self.note {
                    self.dataController?.addPhotographs(with: urlImage, note: note)
                }
            }
        }
    }
    
}
extension DetailNoteViewController : UICollectionViewDataSource{

func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let fetchResultsController = fetchResultsController{
        return fetchResultsController.sections![section].numberOfObjects
    }else {
        return 0
    }
}

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = imageCollectionView?.dequeueReusableCell(withReuseIdentifier: "imageCell",
                                             for: indexPath) as? ImageCollectionViewCell
    guard let photograph = fetchResultsController?.object(at: indexPath) as? PhotographMO else {
        fatalError("Attempt to configure cell without a managed object")
    }

    if let imageData = photograph.imageData,
       let image = UIImage(data: imageData) {
        cell?.configureViews(image: image)
    } else {
        cell?.configureViews(image: nil)
    }
    return cell ?? UICollectionViewCell()
}
}

extension DetailNoteViewController :  NSFetchedResultsControllerDelegate{
    
    //will change
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    //did change a section
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
            case .insert:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            case .delete:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            case .update, .move:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            @unknown default:
                fatalError()
        }
                
    }
    //did change an object
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            case .insert:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.insertItems(at: [newIndexPath!])
                        }
                    })
                )
            case .delete:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.deleteItems(at: [indexPath!])
                        }
                    })
                )
            case .update:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.reloadItems(at: [indexPath!])
                        }
                    })
                )
            case .move:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let blockOperation = self {
                            blockOperation.imageCollectionView?.moveItem(at: indexPath!, to: newIndexPath!)
                        }
                    })
                )
            @unknown default:
                fatalError()
        }
    
    }
    //did change content ,comiteamos los cambios
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        imageCollectionView?.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
}

