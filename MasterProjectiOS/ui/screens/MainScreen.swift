import SwiftUI
import Charts

struct MainScreen: View {
    @StateObject private var viewModel: MainViewModel

    init(viewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Display mode buttons
                HStack(spacing: 64) {
                    Button("Text") {
                        viewModel.updateDisplayMode(to: .text)
                    }
                    Button("Bar") {
                        viewModel.updateDisplayMode(to: .bar)
                    }
                    Button("Graph") {
                        viewModel.updateDisplayMode(to: .graph)
                    }
                }

                Group {
                    switch viewModel.displayMode {
                    case .text:
                        ScrollView {
                            Text(viewModel.displayText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    case .bar:
                        SimpleBarChart(data: viewModel.chartData)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                    case .graph:
                        SimpleLineChart(data: viewModel.chartData)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 400)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Data type picker
                Picker("Data Type", selection: $viewModel.selectedType) {
                    ForEach(viewModel.types, id: \.self) { Text($0) }
                }
                .pickerStyle(MenuPickerStyle())

                // Time range picker
                Picker("Time Range", selection: $viewModel.selectedTime) {
                    ForEach(viewModel.timeOptions, id: \.self) { Text($0) }
                }
                .pickerStyle(MenuPickerStyle())

                // Action buttons
                Button("Read Data") {
                    Task {
                        await viewModel.readHealthDataForSelectedPeriod()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Send Data to DB") {
                    Task {
                        await viewModel.sendHealthDataForSelectedPeriod()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .opacity(viewModel.isLoading ? 0.3 : 1.0)

            // Loading overlay
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Sending data to server...")
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
            }
        }
    }
}


struct SimpleBarChart: View {
    let data: [HealthDataPoint]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd\nHH:mm"
        return formatter
    }

    private var maxY: Double {
        (data.map { $0.value }.max() ?? 1.0) * 1.1 // Add 10% headroom
    }

    var body: some View {
        ScrollView(.horizontal) {
            Chart {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    BarMark(
                        x: .value("Index", index),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(Color.blue)
                    .annotation(position: .bottom) {
                        Text(dateFormatter.string(from: point.timestamp))
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .chartYScale(domain: -25...maxY)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 350)
            .padding()
            .frame(width: CGFloat(data.count) * 36 + 60)
        }
    }
}

struct SimpleLineChart: View {
    let data: [HealthDataPoint]
    @State private var selectedPoint: HealthDataPoint?

    private var maxY: Double {
        (data.map { $0.value }.max() ?? 1.0) * 1.1
    }

    var body: some View {
        ScrollView(.horizontal) {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.red)

                    PointMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(selectedPoint?.id == point.id ? .blue : .red)

                    if selectedPoint?.id == point.id {
                        PointMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", point.value))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...maxY)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisDateFormatter.string(from: date))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if let tappedDate: Date = proxy.value(atX: location.x),
                               let tappedY: Double = proxy.value(atY: location.y) {

                                let nearest = data.min { a, b in
                                    let ax = proxy.position(forX: a.timestamp) ?? .zero
                                    let ay = proxy.position(forY: a.value) ?? .zero
                                    let bx = proxy.position(forX: b.timestamp) ?? .zero
                                    let by = proxy.position(forY: b.value) ?? .zero
                                    let da = hypot(ax - location.x, ay - location.y)
                                    let db = hypot(bx - location.x, by - location.y)
                                    return da < db
                                }

                                if let nearest = nearest,
                                   let px = proxy.position(forX: nearest.timestamp),
                                   let py = proxy.position(forY: nearest.value),
                                   hypot(px - location.x, py - location.y) < 30 {
                                    selectedPoint = nearest
                                }
                            }
                        }
                }
            }
            .frame(height: 300)
            .padding()
            .frame(width: CGFloat(data.count) * 36 + 60)
        }
    }

    private var xAxisDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd\nHH:mm"
        return formatter
    }
}
