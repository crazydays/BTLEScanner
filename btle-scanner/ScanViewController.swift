//
//  ScanViewController.swift
//  BTLE Scanner
//
//  Created by Aaron Day on 8/29/17.
//  Copyright © 2017 Aaron Day. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ScanViewController: NSViewController {

    @IBOutlet weak var scanButton: NSButton!
    @IBOutlet weak var scanningIndicator: NSProgressIndicator!
    @IBOutlet weak var detailButton: NSButton!
    @IBOutlet weak var peripheralTable: NSTableView!

    var bluetoothManager: BluetoothLEManager?
    var scanning: Bool?

    var peripherals: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupScanButton()
        setupDetailButton()
        setupPeripheralTable()
        setupBluetooth()
    }

    func setupScanButton() {
        scanButton.isEnabled = false
        scanButton.title = "Start Scan"
    }

    func setupDetailButton() {
        detailButton.title = "Detail"
    }
    
    func setupPeripheralTable() {
        peripheralTable.delegate = self as? NSTableViewDelegate
        peripheralTable.dataSource = self
        for column in peripheralTable.tableColumns {
            if column.identifier == "name" {
                column.headerCell.title = "Name"
            } else if column.identifier == "identifier" {
                column.headerCell.title = "Identifier"
            }
            
        }
    }

    func setupBluetooth() {
        // hardware
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.bluetoothEnabled), name: Notification.Name(BluetoothLEManager.BTLE_HardwareEnabled), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.bluetoothDisabled), name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: nil)
        
        // scanning
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.bluetoothStartScanning), name: Notification.Name(BluetoothLEManager.BTLE_ScanStart), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.bluetoothStopScanning), name: Notification.Name(BluetoothLEManager.BTLE_ScanStop), object: nil)
        
        // peripheral
        NotificationCenter.default.addObserver(self, selector: #selector(ScanViewController.bluetoothDiscoveredPeripheral), name: Notification.Name(BluetoothLEManager.BTLE_DiscoveredPeripheral), object: nil)

        // reference to bluetooth manager
        let delegate: AppDelegate = NSApplication.shared().delegate as! AppDelegate

        bluetoothManager = delegate.bluetoothManager()
        scanning = false
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }

    func bluetoothEnabled(notification: Notification) {
        scanButton.isEnabled = true
    }

    func bluetoothDisabled() {
        scanButton.isEnabled = false
    }

    func bluetoothStartScanning(notification: Notification) {
        scanButton.title = "Stop Scan"
        scanningIndicator.startAnimation(self)
    }

    func bluetoothStopScanning(notification: Notification) {
        scanButton.title = "Start Scan"
        scanningIndicator.stopAnimation(self)
    }

    func bluetoothDiscoveredPeripheral(notification: Notification) {
        if let peripheral: CBPeripheral = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoPeripheral] as? CBPeripheral {
            if peripherals.contains(peripheral) {
                print("Already seen peripheral: %@", peripheral)
            } else {
                print("Adding peripheral: %@", peripheral)
                peripherals.append(peripheral)
            }
        }
        
        peripheralTable.reloadData()
    }

    // MARK: action
    @IBAction func toggleScan(sender: NSButton) {
        if scanning! {
            print("toggleScan: stopping")
            scanning = false
            bluetoothManager?.stopScan()
        } else {
            print("toggleSacn: starting")
            scanning = true
            bluetoothManager?.startScan()
        }
    }

    @IBAction func showDetailsOfSelectedPeripheral(sender: NSButton) {
        // turn off scanning
        if scanning! {
            toggleScan(sender: scanButton)
        }

        // open / forward peripheral window
        let row: Int = peripheralTable.selectedRow
        let peripheral: CBPeripheral = peripherals[row]
        let delegate: AppDelegate = NSApplication.shared().delegate as! AppDelegate
        let window: NSWindow = delegate.peripheralWindow(peripheral)

        window.makeKeyAndOrderFront(self)

        let controller = NSWindowController(window: window)
        controller.showWindow(self)
    }
}

// MARK: NSTableViewDataSource
extension ScanViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        print("tableView:objectValueFor:row: \(row)")
        print("tableView:objectValueFor:row: identifier - \(tableColumn?.identifier ?? "nil")")
        
        if tableColumn?.identifier == "name" {
            print("tableView:objectValueFor:row: name - \(peripherals[row].name ?? "nil")")
            return peripherals[row].name
        } else if tableColumn?.identifier == "identifier" {
            print("tableView:objectValueFor:row: identifier - \(peripherals[row].identifier.uuidString)")
            return peripherals[row].identifier.uuidString
        } else {
            return "N/F"
        }
    }
}
