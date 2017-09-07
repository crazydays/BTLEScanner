//
//  PeripheralViewController.swift
//  BTLE Scanner
//
//  Created by Aaron Day on 9/4/17.
//  Copyright © 2017 Aaron Day. All rights reserved.
//

import Cocoa
import CoreBluetooth

class PeripheralViewController: NSViewController {

    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var peripheralName: NSTextField!
    @IBOutlet weak var peripheralOutline: NSOutlineView!

    var peripheral: CBPeripheral?
    var bluetoothManager: BluetoothLEManager?
    var connected: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupConnectButton()
        setupPeripheralName()
        setupPeripheralOutline()
        setupBluetooth()
    }

    func setupConnectButton() {
        connectButton.title = "Connect"
    }

    func setupPeripheralName() {
        peripheralName.stringValue = peripheral?.name ?? (peripheral?.identifier.uuidString)!
    }

    func setupPeripheralOutline() {
        peripheralOutline.dataSource = self
    }

    func setupBluetooth() {
        connected = false

        // hardware
//        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.bluetoothEnabled), name: Notification.Name(BluetoothLEManager.BTLE_HardwareEnabled), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.bluetoothDisabled), name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: nil)

        // connections
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.connectedPeripheral), name: Notification.Name(BluetoothLEManager.BTLE_ConnectedPeripheral), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.failedToConnectPeripheral), name: Notification.Name(BluetoothLEManager.BTLE_FailedToConnectPeripheral), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.disconnectedPeripheral), name: Notification.Name(BluetoothLEManager.BTLE_DisconnectedPeripheral), object: nil)

        // peripheral
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.discoveredServices), name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredServices), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.discoveredCharacteristics), name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredCharacteristics), object: nil)

        // reference to bluetooth manager
        let delegate: AppDelegate = NSApplication.shared().delegate as! AppDelegate
        bluetoothManager = delegate.bluetoothManager()
    }

    @IBAction func toggleConnection(sender: NSButton) {
        connectButton.isEnabled = false

        if connected! {
            bluetoothManager?.disconnect(peripheral!)
        } else {
            bluetoothManager?.connect(peripheral!)
        }
    }

    func connectedPeripheral(notification: Notification) {
        print("connectedPeripheral:")
        if isPeripheral(notification) {
            connected = true
            connectButton.isEnabled = true
            connectButton.title = "Disconnect"
        }
    }

    func failedToConnectPeripheral(notification: Notification) {
        print("failedToConnectPeripheral:")
        if isPeripheral(notification) {
            connected = false
            connectButton.isEnabled = true
            connectButton.title = "Connect"
        }
    }

    func disconnectedPeripheral(notification: Notification) {
        print("disconnectedPeripheral:")
        if isPeripheral(notification) {
            connected = false
            connectButton.isEnabled = true
            connectButton.title = "Connect"
        }
    }

    func discoveredServices(notification: Notification) {
        print("discoveredServices:")
        if isPeripheral(notification) {
            peripheralOutline.reloadData()
        }
    }

    func discoveredCharacteristics(notification: Notification) {
        print("discoveredCharacteristics:")
        if isPeripheral(notification) {
            let service: CBService = notification.userInfo![BluetoothLEManager.BTLE_UserInfoService] as! CBService
            peripheralOutline.reloadItem(service)
        }
    }

    func isPeripheral(_ notification: Notification) -> Bool {
        if let notificationPeripheral: CBPeripheral = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoPeripheral] as? CBPeripheral {
            return peripheral == notificationPeripheral
        } else {
            return false
        }
    }
}

// MARK: NSOutlineViewDataSource
extension PeripheralViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        print("outlineView:numberOfChildernOfItem: \(item ?? "nil")")
        if item == nil {
            return peripheral?.services?.count ?? 0
        } else if let service: CBService = item as? CBService {
            return service.characteristics?.count ?? 0
        } else {
            return 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        print("outlineView:childIndex:OfItem: \(index), \(item ?? "nil")")
        if item == nil {
            return (peripheral?.services?[index])!
        } else if let service: CBService = item as? CBService {
            return service.characteristics![index]
        } else {
            return 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        print("outlineView:isItemExpandable: \(item)")
        if let service: CBService = item as? CBService {
            return service.characteristics?.count ?? 0 > 0
        } else {
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        print("outlineView:objectValueForTableColumn:byItem:")
        if tableColumn?.identifier == "name" {
            if let service: CBService = item as? CBService {
                return service.uuid.uuidString
            } else if let characteristic: CBCharacteristic = item as? CBCharacteristic {
                return characteristic.uuid.uuidString
            }
        } else if tableColumn?.identifier == "value" {
            if let _: CBCharacteristic = item as? CBCharacteristic {
                return "Value"
            }
        }

        return nil
    }

//    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
//        print("outlineView:setObjectValue:forTableColumn:byItem:")
//    }

//    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
//    }


//    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
//    }
}
