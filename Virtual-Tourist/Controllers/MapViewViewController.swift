//
//  MapViewViewController.swift
//  Virtual-Tourist
//
//  Created by Sultan on 19/03/18.
//  Copyright © 2018 Sultan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewViewController: UIViewController,MKMapViewDelegate,NSFetchedResultsControllerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController : DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var isEditingStateOn : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMapRegion()
        longPressGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpFetchedResults()
        fetchPinFromCD()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setUpFetchedResults() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }
    
    
    func fetchPinFromCD(){
        mapView.removeAnnotations(mapView.annotations)
        for objects in fetchedResultsController.fetchedObjects!{
            let annotationCoordinate = CLLocationCoordinate2D(latitude: objects.latitude, longitude: objects.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = annotationCoordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func SavePinToCD(Coordinates : CLLocationCoordinate2D){
        let pinToAdd = Pin(context: dataController.viewContext)
        pinToAdd.latitude = Coordinates.latitude
        pinToAdd.longitude = Coordinates.longitude
        do{
            try? dataController.viewContext.save()
        }
        
    }
    
    func longPressGesture(){
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(press:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func addAnnotation(press : UILongPressGestureRecognizer){
        if press.state == .began{
            let locationForAnnotation = press.location(in: mapView)
            let coordinatesForAnnotation = mapView.convert(locationForAnnotation, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinatesForAnnotation
            mapView.addAnnotation(annotation)
            SavePinToCD(Coordinates: coordinatesForAnnotation)
        }
    }
    
    
    fileprivate func DeletePinFromCD(_ viewToDelete: MKAnnotation?, _ mapView: MKMapView) {
        try? fetchedResultsController.performFetch()
        for pins in fetchedResultsController.fetchedObjects!{
            if (pins.latitude == viewToDelete?.coordinate.latitude && pins.longitude == viewToDelete?.coordinate.longitude){
                fetchedResultsController.managedObjectContext.delete(pins)
                mapView.removeAnnotation(viewToDelete!)
                break
            }
        }
        try? dataController.viewContext.save()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if isEditingStateOn{
            DeletePinFromCD(view.annotation, mapView)
        } else {
            performSegue(withIdentifier: "photoCollection", sender: view.annotation)
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoCollection"{
            try? fetchedResultsController.performFetch()
            let destinationVC = segue.destination as? PhotoCollectionViewController
            let coords = sender as! MKAnnotation
            destinationVC?.pinRecieved = coords
            destinationVC?.dataController = dataController
            for pinToSend in fetchedResultsController.fetchedObjects!{
                if(pinToSend.latitude == coords.coordinate.latitude && pinToSend.longitude == coords.coordinate.longitude){
                    destinationVC?.pinSaved = pinToSend
                    break
                }
            }
        }
    }
    
    
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let entity = NSEntityDescription.entity(forEntityName: "MapRegion", in: dataController.viewContext)
        let mapRegionToSave = MapRegion(entity: entity!, insertInto: dataController.viewContext)
        
        mapRegionToSave.centerlatitude = mapView.region.center.latitude
        mapRegionToSave.centerlongitude = mapView.region.center.longitude
        mapRegionToSave.spanlatitude = mapView.region.span.latitudeDelta
        mapRegionToSave.spanlongitude = mapView.region.span.longitudeDelta
        
        try? dataController.viewContext.save()
    }
    
    func setMapRegion(){
        var mapRegions = [MapRegion]()
        let fetchRequest:NSFetchRequest<MapRegion>=MapRegion.fetchRequest()
        do{
            mapRegions = try! dataController.viewContext.fetch(fetchRequest)
        }
        if mapRegions.count > 0 {
            let newMapRegion = mapRegions.last
            let coordinate = CLLocationCoordinate2D(latitude: (newMapRegion?.centerlatitude)!, longitude: (newMapRegion?.centerlongitude)!)
            let span = MKCoordinateSpanMake((newMapRegion?.spanlatitude)!, (newMapRegion?.spanlongitude)!)
            let region = MKCoordinateRegionMake(coordinate, span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    @IBAction func EditButtonSet(_ sender: Any) {
        isEditingStateOn = !isEditingStateOn
        if isEditingStateOn{
            self.navigationItem.title = "Editing Mode on"
        } else {
            self.navigationItem.title = "Map View"
        }
    }
    
}

