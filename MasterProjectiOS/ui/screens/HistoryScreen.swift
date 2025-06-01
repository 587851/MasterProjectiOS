import SwiftUI

struct HistoryScreen: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        if viewModel.groupedRecords.isEmpty {
            VStack {
                Spacer()
                Text("No history data available.")
                    .foregroundColor(.secondary)
                    .font(.body)
                Spacer()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(viewModel.groupedRecords.keys), id: \.self) { timeRange in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(timeRange)
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.groupedRecords[timeRange] ?? [], id: \.id) { record in
                                HistoryRecordItem(record: record)
                            }
                        }
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct HistoryRecordItem: View {
    let record: HistorySample
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(record.dataType) sent on \(formatter.string(from: record.timestamp))")
                .font(.body)

            Text("Data points: \(record.dataPointCount)")
                .font(.caption)

            Text("Period: \(formatter.string(from: record.periodStart)) - \(formatter.string(from: record.periodEnd))")
                .font(.caption)

            Text("Source: \(record.source)")
                .font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))
        .padding(.horizontal)
    }
}

