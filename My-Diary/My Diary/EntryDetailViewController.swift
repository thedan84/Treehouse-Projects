//
//  EntryDetailViewController.swift
//  My Diary
//
//  Created by Dennis Parussini on 16-10-16.
//  Copyright © 2016 Dennis Parussini. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

fileprivate let locationEnabled = "locationEnabled"

class EntryDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: - Properties
    @IBOutlet weak var entryTextView: SAMTextView!
    @IBOutlet weak var entryDateLabel: UILabel!
    @IBOutlet weak var entryImageView: UIImageView!
    @IBOutlet weak var addImageButton: UIButton!
    @IBOutlet weak var enableLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var accessory: UIView!
    var hideKeyboardButton: UIButton!
    
    let coreDataManager = CoreDataManager.sharedManager
    var image: UIImage? {
        didSet {
            self.entryImageView.isHidden = false
            self.addImageButton.isHidden = true
            self.entryImageView.image = image!
        }
    }
    var entry: Entry?
    var imageData: Data?
    var location: CLLocation? {
        didSet {
            addMapAnnotation()
        }
    }
    var locationManager = LocationManager()
    var userDefaults = UserDefaults.standard
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let entry = self.entry {
            self.configureWithEntry(entry: entry)
        } else {
            if userDefaults.bool(forKey: locationEnabled) {
                enableLocationButton.isSelected = true
                userDefaults.synchronize()
                mapView.isHidden = false
                locationManager.getLocation()
                locationManager.onLocationFix = { [weak self] location in
                    self?.location = location
                }
            } else {
                enableLocationButton.isSelected = false
                userDefaults.synchronize()
                mapView.isHidden = true
            }
            
            self.configureToCreateEntry()
        }
        
        let imageRecognizer = UITapGestureRecognizer(target: self, action: #selector(addImageButtonTapped(_:)))
        self.entryImageView.addGestureRecognizer(imageRecognizer)
        imageRecognizer.delegate = self
        
        self.entryTextView.layer.cornerRadius = 20
        self.entryTextView.layer.borderColor = UIColor.lightGray.cgColor
        self.entryTextView.layer.borderWidth = 2
        self.automaticallyAdjustsScrollViewInsets = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.delegate = self
        
        setupKeyboardInput()
    }
    
    //MARK: - View configuration
    func configureWithEntry(entry: Entry) {
        self.entryTextView.text = entry.text
        self.entryDateLabel.text = "Created at \(dateFormatter.string(from: entry.date as Date))"
        
        if let image = entry.image {
            self.entryImageView.image = UIImage(data: image as Data)
            self.addImageButton.isHidden = true
        } else {
            self.addImageButton.isHidden = false
        }
        
        self.location = locationManager.loadLocationForEntry(entry: entry)
    }
    
    func configureToCreateEntry() {
        self.entryTextView.placeholder = "Tap here to enter text"
        self.entryDateLabel.text = "Created at \(dateFormatter.string(from: Date()))"
        self.entryImageView.isHidden = true
        self.addImageButton.isHidden = false
    }
    
    //MARK: - IBActions
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func enableLocationButtonTapped(_ sender: UIButton) {
        switchLocationEnabled()
    }
    
    @IBAction func addImageButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let text = entryTextView.text, !entryTextView.text.isEmpty else { AlertManager.showAlert(with: "Missing Input", andMessage: "Please enter a text", inViewController: self); return }
        
        if let entry = self.entry {
            entry.text = text
            if let imageData = self.imageData {
                entry.image = imageData as NSData
            }
            coreDataManager.saveContext()
        } else {
            coreDataManager.saveEntry(withText: text, andImageData: self.imageData, andLocation: self.location)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Helper functions
    fileprivate func switchLocationEnabled() {
        if userDefaults.bool(forKey: locationEnabled) {
            userDefaults.set(false, forKey: locationEnabled)
            enableLocationButton.isSelected = false
            mapView.isHidden = true
        } else {
            userDefaults.set(true, forKey: locationEnabled)
            enableLocationButton.isSelected = true
            locationManager.getLocation()
            locationManager.onLocationFix = { [weak self] location in
                self?.location = location
            }
            mapView.isHidden = false
        }
        userDefaults.synchronize()
    }
    
    func dismissKeyboard() {
        entryTextView.resignFirstResponder()
    }
    
    func setupKeyboardInput() {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45)
        accessory = UIView(frame: frame)
        accessory.backgroundColor = UIColor.lightGray
        accessory.alpha = 0.6
        accessory.translatesAutoresizingMaskIntoConstraints = false
        
        self.entryTextView.inputAccessoryView = accessory
        
        hideKeyboardButton = UIButton(type: .custom)
        hideKeyboardButton.setTitle("Hide", for: .normal)
        hideKeyboardButton.setTitleColor(.black, for: .normal)
        hideKeyboardButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        hideKeyboardButton.showsTouchWhenHighlighted = true
        hideKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        accessory.addSubview(hideKeyboardButton)
        
        NSLayoutConstraint.activate([
            hideKeyboardButton.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: -20),
            hideKeyboardButton.centerYAnchor.constraint(equalTo: accessory.centerYAnchor)
            ])
    }
}

//MARK: - UIImagePickerControllerDelegate
extension EntryDetailViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = image
            self.imageData = UIImageJPEGRepresentation(image, 1.0)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - MKMapViewDelegate
extension EntryDetailViewController: MKMapViewDelegate {
    func addMapAnnotation() {
        removeMapAnnotations()
        let point = MKPointAnnotation()
        if let coordinate = self.location?.coordinate {
            point.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        var region = MKCoordinateRegion()
        region.center = self.location!.coordinate
        region.span.latitudeDelta = 0.015
        region.span.longitudeDelta = 0.015
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(point)
    }
    
    func removeMapAnnotations() {
        if mapView.annotations.count != 0 {
            for annotation in mapView.annotations {
                mapView.removeAnnotation(annotation)
            }
        }
    }
}
