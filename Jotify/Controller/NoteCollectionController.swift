//
//  NoteCollectionController.swift
//  Zurich
//
//  Created by Harrison Leath on 1/12/21.
//

import UIKit
import Blueprints
import XLActionController

class NoteCollectionController: UICollectionViewController {
    
    //update collection view when model changes
    var noteCollection: NoteCollection? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    
    //layouts for collectionView
    let iOSLayout = VerticalBlueprintLayout(
        itemsPerRow: 2.0,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 15,
        sectionInset: EdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        stickyHeaders: false,
        stickyFooters: false)
    
    let iPadOSLayout = VerticalBlueprintLayout(
        itemsPerRow: 3.0,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 15,
        sectionInset: EdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        stickyHeaders: false,
        stickyFooters: false)
    
    //life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupNavigationBar()
        handleStatusBarStyle(style: .darkContent)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "enableSwipe"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        
//        for note in noteCollection!.FBNotes {
//            DataManager.deleteNote(docID: note.id) { (success) in
//                //
//            }
//        }
    }
    
    //view configuration
    func setupViewElements() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            collectionView.setCollectionViewLayout(iPadOSLayout, animated: true)
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            collectionView.setCollectionViewLayout(iOSLayout, animated: true)
        }
        
        //navigation bar item customization
        let leftItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(handleLeftNavButton))
        navigationItem.leftBarButtonItem = leftItem
        navigationItem.setHidesBackButton(true, animated: true)
        
        collectionView.backgroundColor = ColorManager.bgColor
        collectionView.register(SavedNoteCell.self, forCellWithReuseIdentifier: "SavedNoteCell")
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Saved Notes"
        navigationController?.enablePersistence()
        navigationController?.setColor(color: ColorManager.bgColor)
        navigationController?.navigationBar.titleTextAttributes = nil
    }
    
    //action handlers
    @objc func longTouchHandler(sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: location)
        
        let actionController = SkypeActionController()
        if traitCollection.userInterfaceStyle == .light {
            actionController.backgroundColor = ColorManager.noteColor
        } else {
            actionController.backgroundColor = .mineShaft
        }
        actionController.addAction(Action("Delete note", style: .default, handler: { _ in
            DataManager.deleteNote(docID: (self.noteCollection?.FBNotes[indexPath!.row].id)!) { _ in }
            //display error in UI
        }))
        actionController.addAction(Action("Cancel", style: .cancel, handler: nil))
        present(actionController, animated: true, completion: nil)
    }
    
    
    @objc func handleLeftNavButton() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let vc = GeneralSettingsController(style: .insetGrouped)
            vc.modalPresentationStyle = .formSheet
            navigationController?.present(vc, animated: true, completion: nil)
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.pushViewController(GeneralSettingsController(style: .insetGrouped), animated: true)
        }
    }
    
    //collectionView Logic
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //noteCollection.notes.count will return nil if no notes exist on launch, will return 0 if user deletes a note
        //and num of objs in array go to 0
        if (noteCollection?.FBNotes.count == nil) || (noteCollection?.FBNotes.count == 0){
            collectionView.backgroundView = EmptyNoteView()
        } else {
            //remove backgroundView if array of notes isn't empty
            collectionView.backgroundView = nil
        }
        
        return noteCollection?.FBNotes.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedNoteCell", for: indexPath) as? SavedNoteCell else { fatalError("Wrong cell class dequeued") }
        
        cell.textLabel.text = noteCollection?.FBNotes[indexPath.row].content
        cell.dateLabel.text = noteCollection?.FBNotes[indexPath.row].timestamp.getDate()
        cell.backgroundColor = noteCollection?.FBNotes[indexPath.row].color.getColor()
        
        cell.layer.cornerRadius = 5
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        cell.contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTouchHandler(sender:))))
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.playHapticFeedback()
        let controller = EditingController()
        controller.note = (noteCollection?.FBNotes[indexPath.row])!
        controller.noteCollection = noteCollection
        navigationController?.pushViewController(controller, animated: true)
    }
    
    //traitcollection: dynamic iPad layout and light/dark mode support
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.horizontalSizeClass == .compact {
            iPadOSLayout.itemsPerRow = 1.0
        } else if traitCollection.horizontalSizeClass == .regular {
            iPadOSLayout.itemsPerRow = 3.0
        }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.backgroundColor = ColorManager.bgColor
        navigationController?.setColor(color: ColorManager.bgColor)
        handleStatusBarStyle(style: .darkContent)
    }
}

extension NoteCollectionController: CollectionViewFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            height = 120
        } else {
            height = 110
        }
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
}
