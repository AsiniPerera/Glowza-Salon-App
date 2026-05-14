import SwiftUI

// MARK: - Booking Summary View
// This view shows a summary of the booking before the user proceeds to payment.
struct BookingSummaryView: View {

    @Binding var draft: BookingDraft // Bound to parent to share data.
    let onProceed: () -> Void
    let onBack: () -> Void

    private var appSettings: AppSettings { AppSettings.shared }

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    // Formats the date nicely for display.
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: draft.date)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.themePage).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    GlowzaCircleBackButton(action: onBack)
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 32)

                    // Title section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Booking Summary")
                            .glowzaFont(size: 24, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
                        Text("Review your appointment details before payment")
                            .glowzaFont(size: 17)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 32)

                    // Appointment details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPOINTMENT DETAILS")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            summaryRow(icon: "mappin.and.ellipse", label: "Salon", value: draft.salon.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "bubbles.and.sparkles.fill", label: "Treatment", value: service.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "timer", label: "Duration", value: service.duration)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "calendar.badge.clock", label: "Date", value: formattedDate)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "clock.badge.checkmark", label: "Time", value: draft.timeSlot)
                        }
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Price breakdown card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRICE SUMMARY")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 12) {

                            HStack {
                                Text("Total Amount")
                                    .glowzaFont(size: 17, weight: .semibold)
                                    .foregroundColor(appSettings.themeText)
                                Spacer()
                                Text("LKR \(Int(total))")
                                    .glowzaFont(size: 17, weight: .semibold)
                                    .foregroundColor(.glowzaPrimary)
                            }
                        }
                        .padding(16)
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Route Card
                    // Shows a mini map with a route from the user to the salon.
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ROUTE TO SALON")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        MapViewWithRoute(
                            userLocation: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
                            salonLocation: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)
                        )
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .hcBorder(radius: 12)
                        
                        Button(action: {
                            // Opens Apple Maps with directions!
                            let url = URL(string: "http://maps.apple.com/?saddr=6.9271,79.8612&daddr=6.7730,79.8820")!
                            UIApplication.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Get Directions")
                            }
                            .glowzaFont(size: 14, weight: .semibold)
                            .foregroundColor(.glowzaPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.glowzaPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }

            // Bottom buttons
            VStack(spacing: 0) {
                Button(action: onProceed) {
                    Text("Proceed to Payment")
                        .glowzaFont(size: 17, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(Color.glowzaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                
                Button(action: onBack) {
                    Text("Cancel Booking")
                        .glowzaFont(size: 15, weight: .semibold)
                        .foregroundColor(Color(hex: "8E8E93"))
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 14)
            }
            .background(appSettings.themeSurface)
        }
        .navigationBarHidden(true)
    }

    // Helper to create a consistent row layout.
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(appSettings.themeRaised)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .glowzaFont(size: 14, weight: .semibold)
                    .foregroundColor(.glowzaPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .glowzaFont(size: 12)
                    .foregroundColor(Color(hex: "8E8E93"))
                Text(value)
                    .glowzaFont(size: 15, weight: .semibold)
                    .foregroundColor(appSettings.themeText)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

import MapKit

// MARK: - MapViewWithRoute
// This is a UIViewRepresentable that wraps a UIKit MKMapView.
// We need this because SwiftUI's Map view doesn't easily support drawing routes (overlays) in older iOS versions!
struct MapViewWithRoute: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    let salonLocation: CLLocationCoordinate2D

    // Creates the UIKit view.
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator // Set the delegate to handle overlays!
        
        // Add annotations (pins).
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = userLocation
        userAnnotation.title = "You"
        
        let salonAnnotation = MKPointAnnotation()
        salonAnnotation.coordinate = salonLocation
        salonAnnotation.title = "Salon"
        
        mapView.addAnnotations([userAnnotation, salonAnnotation])
        
        // Create a simulated curved line for the route!
        let points = [
            userLocation,
            CLLocationCoordinate2D(latitude: (userLocation.latitude + salonLocation.latitude) / 2 + 0.01, longitude: (userLocation.longitude + salonLocation.longitude) / 2 - 0.01),
            salonLocation
        ]
        let polyline = MKPolyline(coordinates: points, count: points.count)
        mapView.addOverlay(polyline)
        
        // Set the visible area of the map to fit the route.
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false)
        
        return mapView
    }

    // Updates the view when state changes (not needed here).
    func updateUIView(_ uiView: MKMapView, context: Context) {}

    // Creates the coordinator to act as the MKMapViewDelegate.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // The coordinator class that implements MKMapViewDelegate.
    class Coordinator: NSObject, MKMapViewDelegate {
        // This function tells the map how to render the line (overlay).
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 150/255, green: 32/255, blue: 67/255, alpha: 1) // Brand color.
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
