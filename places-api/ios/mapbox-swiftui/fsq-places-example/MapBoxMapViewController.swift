//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import UIKit
import CoreLocation
import MapboxMaps

final class MapBoxMapViewController: UIViewController, LocationPermissionsDelegate {
    private enum Constants {
        static let ICON_KEY = "icon_key"
        static let RED_MARKER_PROPERTY = "icon_red_property"
        static let RED_ICON_ID = UUID().uuidString
        static let SOURCE_ID = "source_id"
        static let LAYER_ID = "layer_id"
        static let selectedAddCoefPX: CGFloat = 50
    }

    private var mapView: MapView!
    private var pointAnnotationManager: PointAnnotationManager!
    private var cameraLocationConsumer: CameraLocationConsumer!

    private let image = UIImage(named: "red_pin")!
    private lazy var markerHeight: CGFloat = image.size.height

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraLocationConsumer = CameraLocationConsumer(mapView: mapView)
        
        mapView.mapboxMap.onNext(event: .mapLoaded) { [weak self] _ in
            guard let self = self else { return }
            // Register the location consumer with the map
            // Note that the location manager holds weak references to consumers, which should be retained
            self.mapView.location.addLocationConsumer(newConsumer: self.cameraLocationConsumer)
        }
        
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self
        
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.delegate = self
        
        self.view.addSubview(mapView)
        
        let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(options: FollowPuckViewportStateOptions())
        mapView.viewport.transition(to: followPuckViewportState,
                                    transition: mapView.viewport.makeImmediateViewportTransition())
        
        prepareStyle()
    }
    
    @objc private func onMapClick(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        addViewAnnotation(at: mapView.mapboxMap.coordinate(for: sender.location(in: mapView)), title: "Tapped", markerId: UUID().uuidString)
    }
    
    public func addPointAndViewAnnotation(at coordinate: CLLocationCoordinate2D, title: String) {
        let markerId = UUID().uuidString
        addPointAnnotation(at: coordinate, markerId: markerId)
        addViewAnnotation(at: coordinate, title: title, markerId: markerId)
    }

    private func addPointAnnotation(at coordinate: CLLocationCoordinate2D, markerId: String) {
        var pointAnnotation = PointAnnotation(id: markerId, coordinate: coordinate)
        pointAnnotation.iconImage = Constants.RED_ICON_ID
        pointAnnotation.iconAnchor = .bottom
        pointAnnotationManager.annotations.append(pointAnnotation)
    }
    
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D, title: String, markerId: String) {
        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: 128,
            height: 64,
            associatedFeatureId: markerId,
            allowOverlap: false,
            anchor: .bottom,
            offsetY: markerHeight
        )
        let annotationView = AnnotationView(frame: CGRect(x: 0, y: 0, width: 128, height: 64))
        annotationView.title = title
        try? mapView.viewAnnotations.add(annotationView, options: options)
    }

    func removeAllAnnotations() {
        mapView.viewAnnotations.removeAll()
        pointAnnotationManager.annotations.removeAll()
    }
    
    private func prepareStyle() {
        let style = mapView.mapboxMap.style
        try? style.addImage(UIImage(named: "red_pin")!, id: Constants.RED_ICON_ID)

        let source = GeoJSONSource()

        try? style.addSource(source, id: Constants.SOURCE_ID)
        
        let rotateExpression = Exp(.match) {
            Exp(.get) { Constants.ICON_KEY }
            45
            0
        }
        let imageExpression = Exp(.match) {
            Exp(.get) { Constants.ICON_KEY }
            Constants.RED_MARKER_PROPERTY
            Constants.RED_ICON_ID
            Constants.RED_ICON_ID
        }
        var layer = SymbolLayer(id: Constants.LAYER_ID)
        layer.source = Constants.SOURCE_ID
        layer.iconImage = .expression(imageExpression)
        layer.iconAnchor = .constant(.bottom)
        layer.iconAllowOverlap = .constant(false)
        layer.iconRotate = .expression(rotateExpression)
        try? style.addLayer(layer)
    }
    
    public func updateCameraView(north: Double, east: Double, south: Double, west: Double) {
        let bounds = CoordinateBounds(southwest: CLLocationCoordinate2D(latitude: south, longitude: west),
                                      northeast: CLLocationCoordinate2D(latitude: north, longitude: east))
        let camera = mapView.mapboxMap.camera(for: bounds, padding: .zero, bearing: 0, pitch: 0)
        mapView.mapboxMap.setCamera(to: camera)
    }
    
    public func updateCameraView(center: CLLocationCoordinate2D) {
        let camOptions = CameraOptions(center: center)
        mapView.camera.ease(to: camOptions, duration: 3)
    }

    public class CameraLocationConsumer: LocationConsumer {
        weak var mapView: MapView?
        
        init(mapView: MapView) {
            self.mapView = mapView
        }
        
        public func locationUpdate(newLocation: Location) {
            mapView?.camera.ease(
                to: CameraOptions(center: newLocation.coordinate, zoom: 11),
                duration: 1.3)
        }
    }
}

extension MapBoxMapViewController: AnnotationInteractionDelegate {
    func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
    }
}
