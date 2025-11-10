//
//  ProcessItem.swift
//  TaskManager
//
//  Simple model representing a process/process row
//

import Foundation

struct ProcessItem: Identifiable, Hashable {
    let pid: Int
    let ppid: Int
    let name: String
    let cpu: Double
    let mem: Double

    var id: Int { pid }
}
