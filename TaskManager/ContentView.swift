//
//  ContentView.swift
//  TaskManager
//
//  Created by Maty Pierník on 10.11.2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case processes = "Processes"
        case apps = "Apps"
        case performance = "Performance"
        var id: String { rawValue }
    }

    @StateObject private var store = ProcessStore()
    @State private var selectedTab: Tab = .processes
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Task Manager")
                    .font(.title2)
                    .bold()
                    .accessibilityIdentifier("mainTitle")
                    .accessibilityLabel("Task Manager")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHidden(false)
                Spacer()

                Picker("Tab", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)

                Button(action: { Task { await store.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("mainTitleElement")
            .accessibilityLabel("Task Manager")
            .padding([.leading, .trailing, .top])
            .padding(.bottom, 6)

            Divider()

            Group {
                switch selectedTab {
                case .processes:
                    processView
                case .apps:
                    appsView
                case .performance:
                    performanceView
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 420)
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    var processView: some View {
        HSplitView {
            List(selection: $store.selected) {
                ForEach(store.processes) { p in
                    HStack(spacing: 12) {
                        Text(String(p.pid))
                            .frame(width: 60, alignment: .leading)
                            .font(.system(.body, design: .monospaced))

                        VStack(alignment: .leading) {
                            Text(p.name)
                                .lineLimit(1)
                                .font(.body)
                            Text("PPID: \(p.ppid)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.1f%%", p.cpu))
                                .font(.body)
                            Text(String(format: "%.1f%%", p.mem))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .tag(p)
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 340)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                if let sel = store.selected {
                    Text(sel.name)
                        .font(.title2)
                        .bold()

                    HStack(spacing: 16) {
                        Text("PID: \(sel.pid)")
                        Text("PPID: \(sel.ppid)")
                        Text(String(format: "CPU: %.1f%%", sel.cpu))
                        Text(String(format: "MEM: %.1f%%", sel.mem))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Spacer()

                    HStack {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await store.kill(pid: sel.pid)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } label: {
                            Label("End Task", systemImage: "xmark.octagon")
                        }

                        Button {
                            Task { await store.refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                } else {
                    Text("Select a process to see details")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(minWidth: 300)
        }
    }

    var appsView: some View {
        let apps = NSWorkspace.shared.runningApplications
            .compactMap { app -> (name: String, bundleID: String?)? in
                guard let name = app.localizedName else { return nil }
                return (name: name, bundleID: app.bundleIdentifier)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }

        return VStack(alignment: .leading) {
            List(apps, id: \.name) { app in
                HStack {
                    Text(app.name)
                    Spacer()
                    Text(app.bundleID ?? "—")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 6)
            }
            .listStyle(.inset)
        }
    }

    var performanceView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.title2)
                .bold()

            let topCPU = store.processes.prefix(8).map { $0.cpu }.reduce(0, +)
            Text("Approx. CPU (top processes sum): \(String(format: "%.1f", topCPU))%")

            ProgressView(value: min(topCPU/100.0, 1.0))
                .progressViewStyle(.linear)

            let physical = ProcessInfo.processInfo.physicalMemory
            let usedMemoryPercent = store.processes.prefix(8).map { $0.mem }.reduce(0, +)
            Text("Physical memory: \(ByteCountFormatter.string(fromByteCount: Int64(physical), countStyle: .memory))")
            Text(String(format: "Approx. memory (top processes sum): %.1f%%", usedMemoryPercent))

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
