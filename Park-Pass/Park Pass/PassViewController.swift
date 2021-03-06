//
//  PassViewController.swift
//  Park Pass
//
//  Created by Dennis Parussini on 12-06-16.
//  Copyright © 2016 Dennis Parussini. All rights reserved.
//

import UIKit

class PassViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var guestImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var passTypeLabel: UILabel!
    @IBOutlet weak var rideAccessLabel: UILabel!
    @IBOutlet weak var foodDiscountLabel: UILabel!
    @IBOutlet weak var merchDiscountLabel: UILabel!
    @IBOutlet weak var testResultView: UIView!
    @IBOutlet weak var testResultLabel: UILabel!
    
    //MARK: - Properties
    var guest: EntrantType?
    
    //MARK: - View lifecycle
    //viewDidLoad() updates it's subviews dependent on the guest passed in
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guestImageView.image = UIImage(named: "FaceImageAsset")
        
        if let name = guest?.pass?.entrantName {
            nameLabel.text = name
        } else {
            nameLabel.isHidden = true
        }
        
        if let passType = guest?.pass?.type {
            passTypeLabel.text = passType
        } else {
            passTypeLabel.isHidden = true
        }
        
        if let rideAccesses = guest?.pass?.rideAccess {
            if rideAccesses.isEmpty {
                self.rideAccessLabel.isHidden = true
            } else {
                for access in rideAccesses {
                    switch access {
                    case .allRides:
                        rideAccessLabel.text = "Unlimited Rides"
                    case .skipAllRideLines:
                        rideAccessLabel.text = "Unlimited Rides; Skip All Ride Lines"
                    }
                }                
            }
        }
        
        if let discountAccessess = guest?.pass?.discountAccess {
            for access in discountAccessess {
                switch access {
                case .discountOnFood(let discount):
                    if discount != 0 {
                        foodDiscountLabel.text = "\(discount)% discount on Food"
                    } else {
                        foodDiscountLabel.text = "0% discount on Food"
                    }
                case .discountOnMerchandise(let discount):
                    if discount != 0 {
                        merchDiscountLabel.text = "\(discount)% on Merchandise"
                    } else {
                        merchDiscountLabel.text = "0% discount on Merchandise"
                    }
                }
            }
        } else {
            foodDiscountLabel.text = "0% discount on Food"
            merchDiscountLabel.text = "0% discount on Merchandise"
        }
    }
    
    //MARK: - Action methods
    //The functions below use the 'swipe' methods created in Project 4 to test access to the various areas
    //Tests if the entrant has access to amusement areas
    @IBAction func testAmusementAreaAccessTapped(_ sender: UIButton) {
        try! guest?.swipePass(forArea: .amusementAreas) { result in
            self.updateTestResultViewForResult(result)
        }
    }
    
    //Tests if the entrant has ride access
    @IBAction func testRideAccessTapped(_ sender: UIButton) {
        try! guest?.swipePass(forRide: .allRides) { result in
            self.updateTestResultViewForResult(result)
        }
    }
    
    //Tests if the entrant has access to the kitchen
    @IBAction func testKitchenAccessTapped(_ sender: UIButton) {
        try! guest?.swipePass(forArea: .kitchenAreas) { result in
            self.updateTestResultViewForResult(result)
            
        }
    }
    
    //Tests if the entrant has access to maintenance areas
    @IBAction func testMaintenanceAccessTapped(_ sender: UIButton) {
        try! guest?.swipePass(forArea: .maintenanceAreas) { result in
            self.updateTestResultViewForResult(result)
        }
    }
    
    //Tests if the entrant has access to office areas
    @IBAction func testOfficeAccessTapped(_ sender: UIButton) {
        try! guest?.swipePass(forArea: .officeAreas) { result in
            self.updateTestResultViewForResult(result)
            
        }
    }
    
    //Dismisses the view
    @IBAction func createNewPassButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //Helper method to update the 'test result view'
    func updateTestResultViewForResult(_ result: Bool) {
        switch result {
        case true:
            testResultView.backgroundColor = UIColor(red: 0, green: 185/255, blue: 0, alpha: 1.0)
            testResultLabel.text = "Access Granted"
            testResultLabel.textColor = .white
            testResultLabel.font = .systemFont(ofSize: 25)
        case false:
            testResultView.backgroundColor = UIColor(red: 255/255, green: 0, blue: 41/255, alpha: 1.0)
            testResultLabel.text = "Access Denied"
            testResultLabel.textColor = .white
            testResultLabel.font = .systemFont(ofSize: 25)
        }
    }
}
