//
//  AppDelegate.swift
//  BTLE Scanner
//
//  Created by Aaron Day on 8/29/17.
//  Copyright © 2017 Aaron Day. All rights reserved.
//

import Cocoa
import CoreBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var windowByPeripheral: [CBPeripheral: NSWindow] = [:]

    var bluetoothLEManagerInstance: BluetoothLEManager?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func bluetoothManager() -> BluetoothLEManager? {
        if bluetoothLEManagerInstance == nil {
            bluetoothLEManagerInstance = BluetoothLEManager()
        }
 
        return bluetoothLEManagerInstance
    }

    func peripheralWindow(_ peripheral: CBPeripheral) -> NSWindow {
        if let window: NSWindow = windowByPeripheral[peripheral] {
            return window
        } else {
            let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)

            let peripheralViewController: PeripheralViewController = storyboard.instantiateController(withIdentifier: "PeripheralViewController") as! PeripheralViewController
            peripheralViewController.peripheral = peripheral

            let window: NSWindow = NSWindow(contentViewController: peripheralViewController)

            windowByPeripheral[peripheral] = window

            return window
        }
    }
}

