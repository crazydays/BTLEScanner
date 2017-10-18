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
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.discoveredCharacteristicDescriptor), name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredCharacteristicDescriptor), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.characteristicValueUpdated), name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_CharacteristicUpdatedValue), object: nil)
    }

    @IBAction func toggleConnection(sender: NSButton) {
        connectButton.isEnabled = false

        if connected! {
            BluetoothLEManager.shared.disconnect(peripheral!)
        } else {
            BluetoothLEManager.shared.connect(peripheral!)
        }
    }

    @objc func connectedPeripheral(notification: Notification) {
        // print("connectedPeripheral:")
        if isPeripheral(notification) {
            connected = true
            connectButton.isEnabled = true
            connectButton.title = "Disconnect"
        }
    }

    @objc func failedToConnectPeripheral(notification: Notification) {
        // print("failedToConnectPeripheral:")
        if isPeripheral(notification) {
            connected = false
            connectButton.isEnabled = true
            connectButton.title = "Connect"
        }
    }

    @objc func disconnectedPeripheral(notification: Notification) {
        // print("disconnectedPeripheral:")
        if isPeripheral(notification) {
            connected = false
            connectButton.isEnabled = true
            connectButton.title = "Connect"
        }
    }

    @objc func discoveredServices(notification: Notification) {
        // print("discoveredServices:")
        if isPeripheral(notification) {
            peripheralOutline.reloadData()
        }
    }

    @objc func discoveredCharacteristics(notification: Notification) {
        // print("discoveredCharacteristics:")
        if isPeripheral(notification) {
            let service = notification.userInfo![BluetoothLEManager.BTLE_UserInfoService] as! CBService
            peripheralOutline.reloadItem(service)
        }
    }

    @objc func discoveredCharacteristicDescriptor(notification: Notification) {
        // print("discoveredCharacteristicDescriptor:")
        if isPeripheral(notification) {
            let characteristic = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoCharacteristic] as! CBCharacteristic
            peripheralOutline.reloadItem(characteristic)
        }
    }

    @objc func characteristicValueUpdated(notification: Notification) {
        // print("characteristicValueUpdated:")
        if isPeripheral(notification) {
            let characteristic = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoCharacteristic] as! CBCharacteristic
            peripheralOutline.reloadItem(characteristic)
        }
    }

    func isPeripheral(_ notification: Notification) -> Bool {
        guard let notificationPeripheral = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoPeripheral] as? CBPeripheral else {
            return false
        }
        return peripheral == notificationPeripheral
    }
}

// MARK: NSOutlineViewDataSource
extension PeripheralViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // print("outlineView:numberOfChildernOfItem: \(item ?? "nil")")
        if item == nil {
            return peripheral?.services?.count ?? 0
        } else if let service = item as? CBService {
            return service.characteristics?.count ?? 0
        } else {
            return 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // print("outlineView:childIndex:OfItem: \(index), \(item ?? "nil")")
        if item == nil {
            return (peripheral?.services?[index])!
        } else if let service = item as? CBService {
            return service.characteristics![index]
        } else {
            return 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // print("outlineView:isItemExpandable: \(item)")
        if let service = item as? CBService {
            return service.characteristics?.count ?? 0 > 0
        } else {
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        // print("outlineView:objectValueForTableColumn:byItem: \(tableColumn?.identifier ?? "unknown") \(item ?? "nil")")
        if tableColumn?.identifier.rawValue == "name" {
            if let service = item as? CBService {
                return service.uuid.uuidString
            } else if let characteristic = item as? CBCharacteristic {
                return characteristic.uuid.uuidString
            }
        } else if tableColumn?.identifier.rawValue == "value" {
            if let characteristic = item as? CBCharacteristic {
                return characteristic.value?.reduce("") { s, b in s?.appendingFormat("%02x", b) }
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
