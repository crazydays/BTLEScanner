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

    var peripheral: CBPeripheral?
    var bluetoothManager: BluetoothLEManager?
    var connected: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupConnectButton()
        setupBluetooth()
    }

    func setupConnectButton() {
        connectButton.title = "Connect"
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

    func isPeripheral(_ notification: Notification) -> Bool {
        if let notificationPeripheral: CBPeripheral = notification.userInfo?[BluetoothLEManager.BTLE_UserInfoPeripheral] as? CBPeripheral {
            return peripheral == notificationPeripheral
        } else {
            return false
        }
    }
}
