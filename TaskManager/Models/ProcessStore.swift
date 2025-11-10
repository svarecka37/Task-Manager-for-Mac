//
//  ProcessStore.swift
//  TaskManager
//
//  ObservableObject to fetch processes (via `ps`) and provide kill functionality.
//

import Foundation
import Combine

@MainActor
final class ProcessStore: ObservableObject {
    @Published var processes: [ProcessItem] = []
    @Published var selected: ProcessItem? = nil

    private var timer: Timer?

    init() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() async {
        let output = runPS()
        let parsed = Self.parsePS(output: output)
        processes = parsed.sorted { $0.cpu > $1.cpu }
    }

    private func runPS() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,ppid,comm,%cpu,%mem"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
    }

    /// Parse output of `ps -axo pid,ppid,comm,%cpu,%mem` into ProcessItem array.
    /// Made `internal` (module) so tests can call it.
    nonisolated static func parsePS(output: String) -> [ProcessItem] {
        var lines = output.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count > 0 else { return [] }
        // first line is header
        lines.removeFirst()
        var results: [ProcessItem] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let comps = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if comps.count >= 5 {
                let pidStr = comps[0]
                let ppidStr = comps[1]
                let cpuStr = comps[comps.count - 2]
                let memStr = comps[comps.count - 1]
                let nameParts = comps[2..<(comps.count - 2)]
                let name = nameParts.joined(separator: " ")
                if let pid = Int(pidStr), let ppid = Int(ppidStr),
                   let cpu = Double(cpuStr.replacingOccurrences(of: ",", with: ".")),
                   let mem = Double(memStr.replacingOccurrences(of: ",", with: ".")) {
                    results.append(ProcessItem(pid: pid, ppid: ppid, name: name, cpu: cpu, mem: mem))
                }
            }
        }
        return results
    }

    /// Attempts to terminate a process. Tries SIGTERM first, then SIGKILL if still present.
    func kill(pid: Int) async throws {
        // send SIGTERM
        if Darwin.kill(pid_t(pid), SIGTERM) != 0 {
            let e = errno
            if e == ESRCH {
                // already gone
                return
            } else if e == EPERM {
                throw NSError(domain: "ProcessStore", code: Int(e), userInfo: [NSLocalizedDescriptionKey: "Permission denied"]) }
            else {
                // fallback: try SIGKILL
                _ = Darwin.kill(pid_t(pid), SIGKILL)
            }
        }

        // short wait
        try? await Task.sleep(nanoseconds: 300_000_000)

        // check if still exists (kill 0) and force if needed
        if Darwin.kill(pid_t(pid), 0) == 0 {
            if Darwin.kill(pid_t(pid), SIGKILL) != 0 {
                throw NSError(domain: "ProcessStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to kill process"])
            }
        }

        await refresh()
    }
}
