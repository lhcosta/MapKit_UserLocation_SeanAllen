//
//  ViewController.swift
//  MapKit_UserLocation_SeanAllen
//
//  Created by Lucas Costa  on 10/10/19.
//  Copyright © 2019 LucasCosta. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    private var locationManager : CLLocationManager!
    
    @IBOutlet weak var address: UILabel!
    
    private var previousLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view. 
        
        self.mapView.delegate = self
        self.checkLocationServices()
    }
    
    func centerView() {
        if let coordinate = self.locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            self.mapView.setRegion(region, animated: true)
        }
    }
        
    func checkLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
            self.checkLocationAuthorization()
        }
        
    }
    
    func setupLocationManager() {
         self.locationManager = CLLocationManager()
         self.locationManager.delegate = self
         self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
     }
    
    func checkLocationAuthorization() {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            
            self.mapView.showsUserLocation = true
            self.centerView()
            self.locationManager.startUpdatingLocation()
            
            self.previousLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            
        case .denied:
            break
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        default:
            break
        }
        
    }
    
    
    @IBAction func goToLocation(_ sender: Any) {
        
        guard let location = self.locationManager.location else { return }
        
        let request = createDirectionsRequest(coordinate: location.coordinate)
        
        let direction = MKDirections(request: request)
        
        direction.calculate { [unowned self] (response, error) in
            
            if let error = error {
                print("ERROR -> \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {return}
            
            for route in response.routes {
        
                print("STEPS -- \(route.steps.first!.distance)")
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                 
            }
            
        }

        
    }
    
    //3 -- Parte
    func createDirectionsRequest(coordinate : CLLocationCoordinate2D) -> MKDirections.Request {
        
        let destinationCoordinate = CLLocationCoordinate2D(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        
        return request
    }
    

}

extension ViewController : MKMapViewDelegate {
    
    //2 -- Parte
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = previousLocation else { return }
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        //Convertendo location em nomes de lugares(ruas/cidades)
        geoCoder.reverseGeocodeLocation(center) { [unowned self] (placemark, error) in
            
            if let error = error {
                print("ERROR -> \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemark?.first else { return }
            
            guard let steetName = placemark.thoroughfare else {return}
            
            guard let streetNumber = placemark.subThoroughfare else {return}
            
            DispatchQueue.main.async {
                self.address.text = "\(steetName) - \(streetNumber)"
            }
            
        }
        
    }
    
    //3 -- Parte
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        var renderer : MKPolylineRenderer!
        
        if let polyline = overlay as? MKPolyline {
            renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .green
        }
        
        return renderer
    }
    
    
}

extension ViewController : CLLocationManagerDelegate {
    
    //1 -- Parte
    //Changing the location
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        
//        guard let location = locations.last else { return }
//        
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        
//        let region = MKCoordinateRegion(center: center, latitudinalMeters: 10000, longitudinalMeters: 10000)
//        
//        self.mapView.setRegion(region, animated: true)
//        
//    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
     
    
    
}
