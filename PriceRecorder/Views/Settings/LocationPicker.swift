//
//  LocationPicker.swift
//  PriceRecorder
//
//  地图位置选择器
//

import SwiftUI
import MapKit

struct LocationPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var address: String

    func makeUIViewController(context: Context) -> UINavigationController {
        let mapVC = LocationPickerMapViewController(address: $address)
        let navVC = UINavigationController(rootViewController: mapVC)
        return navVC
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}

class LocationPickerMapViewController: UIViewController, MKMapViewDelegate {
    @Binding var address: String
    private let mapView = MKMapView()
    private let geocoder = CLGeocoder()

    init(address: Binding<String>) {
        self._address = address
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "选择位置"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(confirm)
        )

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(gesture)

        if !address.isEmpty {
            geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
                if let placemark = placemarks?.first, let location = placemark.location {
                    let region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    DispatchQueue.main.async {
                        self?.mapView.setRegion(region, animated: true)
                        self?.addAnnotation(at: location.coordinate)
                    }
                }
            }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        mapView.removeAnnotations(mapView.annotations)
        addAnnotation(at: coordinate)

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                if let country = placemark.country { addressComponents.append(country) }
                if let administrativeArea = placemark.administrativeArea { addressComponents.append(administrativeArea) }
                if let locality = placemark.locality { addressComponents.append(locality) }
                if let thoroughfare = placemark.thoroughfare { addressComponents.append(thoroughfare) }
                if let subThoroughfare = placemark.subThoroughfare { addressComponents.append(subThoroughfare) }

                let address = addressComponents.joined(separator: " ")
                DispatchQueue.main.async {
                    self?.address = address
                    self?.title = address.isEmpty ? "选择位置" : address
                }
            }
        }
    }

    private func addAnnotation(at coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func confirm() {
        dismiss(animated: true)
    }
}

#Preview {
    LocationPicker(address: .constant(""))
}
