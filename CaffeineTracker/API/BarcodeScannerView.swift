//
//  BarcodeScannerView.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

import SwiftUI
import VisionKit

/// A SwiftUI view that wraps the VisionKit DataScannerViewController to scan barcodes.
/// This view handles barcode scanning and returns the scanned value via a callback.
/// It also manages dismissal of the scanner view upon a successful scan.
struct BarcodeScannerView: UIViewControllerRepresentable {
    // Environment variable to dismiss the view when scanning is complete
    @Environment(\.dismiss) var dismiss
    
    // Callback closure to handle the scanned barcode string
    var onScan: (String) -> Void

    // Creates and configures the UIKit DataScannerViewController
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode()], // Only recognize barcodes
            qualityLevel: .balanced, // Balanced quality and performance
            recognizesMultipleItems: false, // Only one barcode at a time
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator // Set delegate to handle scanning events
        return vc
    }

    // Updates the UIViewController when SwiftUI state changes (not needed here)
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    // Creates the coordinator object to act as delegate for the scanner
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, dismiss: dismiss)
    }

    // Coordinator class to handle DataScannerViewControllerDelegate callbacks
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        let dismiss: DismissAction
        
        init(onScan: @escaping (String) -> Void, dismiss: DismissAction) {
            self.onScan = onScan
            self.dismiss = dismiss
        }
        
        // Called when new recognized items are added (e.g., barcodes detected)
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            for item in addedItems {
                // Check if the recognized item is a barcode with a valid payload string
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                    onScan(payload) // Pass scanned barcode string to callback
                    dismiss() // Dismiss the scanner view after first successful scan
                }
            }
        }
    }
}
