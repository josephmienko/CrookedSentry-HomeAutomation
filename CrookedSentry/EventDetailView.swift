import SwiftUI
import AVKit

struct EventDetailView: View {
    let event: FrigateEvent
    let onMarkAsReviewed: ((String) async -> Void)?
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var showingVideoPlayerSheet = false
    @State private var showingSnapshotSheet = false
    @State private var hasTriggeredMarkReviewed = false
    
    init(event: FrigateEvent, onMarkAsReviewed: ((String) async -> Void)? = nil) {
        self.event = event
        self.onMarkAsReviewed = onMarkAsReviewed
    }

    private var scoreFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }
    
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // In-progress event notice
                if event.end_time == nil {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.error)
                            .frame(width: 8, height: 8)
                        
                        Text("This event is currently in progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.error)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.error.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let fullSizeSnapshotUrl = event.fullSizeSnapshotUrl(baseURL: settingsStore.frigateBaseURL) {
                    Button(action: {
                        showingSnapshotSheet = true
                    }) {
                        RemoteImage(url: fullSizeSnapshotUrl) {
                            ProgressView()
                        } content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                        }
                    }
                    .buttonStyle(.plain)
                }



                Text("Object: \(event.friendlyLabelName)")
                    .font(.title2)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Camera: \(event.friendlyCameraName)")
                    .font(.title3)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("Start Time: \(Date(timeIntervalSince1970: event.start_time), formatter: itemFormatter)")
                    .foregroundColor(.white)
                    .font(.callout)
                    
                if let duration = event.duration {
                    Text("Duration: \(durationFormatter.string(from: duration) ?? "")")
                        .foregroundColor(.white)
                        .font(.callout)
                } else {
                    Text("End Time: In Progress")
                        .foregroundColor(.white)
                        .font(.callout)
                }

                if !event.zones.isEmpty {
                    Text("Zones: \(event.friendlyZoneNames)")
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.callout)
                }
                Text("Has Clip: \(event.has_clip ? "Yes" : "No")")
                    .foregroundColor(.white)
                    .font(.callout)
                Text("Has Snapshot: \(event.has_snapshot ? "Yes" : "No")")
                    .foregroundColor(.white)
                    .font(.callout)

                // Video Play Button
                if event.has_clip {
                    Button(action: {
                        showingVideoPlayerSheet = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play Video")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                    
                
                if let falsePositive = event.false_positive {
                    Text("False Positive: \(falsePositive ? "Yes" : "No")")
                        .foregroundColor(.white)
                        .font(.callout)
                }
                
                if let plusId = event.plus_id {
                    Text("Plus ID: \(plusId)")
                        .foregroundColor(.white)
                        .font(.callout)
                }
                
                Text("Retain Indefinitely: \(event.retain_indefinitely ? "Yes" : "No")")
                    .foregroundColor(.white)
                    .font(.callout)
                
                if let subLabel = event.sub_label {
                    Text("Sub Label: \(subLabel)")
                        .foregroundColor(.white)
                        .font(.callout)
                }

                // You can add more details from the 'data' object here if needed
                if let eventData = event.data {
                    Divider().background(Color.gray)
                    Text("Detection Details:")
                        .font(.headline)
                        .foregroundColor(.white)
                        
                    Text("Type: \(eventData.type)")
                        .foregroundColor(.white)
                        .font(.body)
                    Text("Score: \(scoreFormatter.string(from: NSNumber(value: eventData.score)) ?? "")")
                        .foregroundColor(.white)
                        .font(.body)
                    Text("Top Score: \(scoreFormatter.string(from: NSNumber(value: eventData.top_score)) ?? "")")
                        .foregroundColor(.white)
                        .font(.body)
                    if !eventData.attributes.isEmpty {
                        Text("Attributes: \(eventData.attributes.joined(separator: ", "))")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    Text("Box: [\(eventData.box.map { String(format: "%.2f", $0) }.joined(separator: ", "))]")
                        .foregroundColor(.white)
                        .font(.body)
                    Text("Region: [\(eventData.region.map { String(format: "%.2f", $0) }.joined(separator: ", "))]")
                        .foregroundColor(.white)
                        .font(.body)
            }
            }
            .padding()
            #if !targetEnvironment(macCatalyst)
            .navigationTitle("Event Details")
            #endif
            .foregroundColor(.white) // Set navigation title color
            .background(Color.black)
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingVideoPlayerSheet) {
            if let clipUrl = event.clipUrl(baseURL: settingsStore.frigateBaseURL) {
                VideoPlayerView(
                    videoURL: clipUrl,
                    event: event,
                    baseURL: settingsStore.frigateBaseURL,
                    onDismiss: {
                        showingVideoPlayerSheet = false
                    }
                )
            } else {
                Text("Video not available.")
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showingSnapshotSheet) {
            if let fullSizeSnapshotUrl = event.fullSizeSnapshotUrl(baseURL: settingsStore.frigateBaseURL) {
                SnapshotView(imageUrl: fullSizeSnapshotUrl)
            } else {
                Text("Snapshot not available.")
                    .foregroundColor(.white)
            }
        }
        .task {
            // Only mark as reviewed if the event has ended (has an end_time)
            // In-progress events should not be marked as reviewed
            if event.end_time != nil, let onMarkAsReviewed = onMarkAsReviewed {
                print("🧭 EventDetailView.task: will mark as reviewed for id=\(event.id), end_time=\(String(describing: event.end_time))")
                await onMarkAsReviewed(event.id)
                hasTriggeredMarkReviewed = true
            } else {
                print("🧭 EventDetailView.task: not marking reviewed (end_time=\(String(describing: event.end_time)), callbackNil=\(onMarkAsReviewed == nil))")
            }
        }
        .onAppear {
            // Defensive: ensure we trigger once upon appearance if .task didn't fire
            if !hasTriggeredMarkReviewed, event.end_time != nil {
                if let onMarkAsReviewed = onMarkAsReviewed {
                    print("🧭 EventDetailView.onAppear: marking as reviewed for id=\(event.id)")
                    hasTriggeredMarkReviewed = true
                    Task { await onMarkAsReviewed(event.id) }
                } else {
                    print("🧭 EventDetailView.onAppear: callback is nil; cannot mark as reviewed for id=\(event.id)")
                }
            } else {
                print("🧭 EventDetailView.onAppear: not marking (hasTriggered=\(hasTriggeredMarkReviewed), end_time=\(String(describing: event.end_time)))")
            }
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(event: FrigateEvent(
            id: "12345.6789-test",
            camera: "front_door",
            label: "person",
            start_time: Date().timeIntervalSince1970 - 3600,
            end_time: Date().timeIntervalSince1970,
            has_clip: true,
            has_snapshot: true,
            zones: ["porch", "driveway"],
            data: EventData(
                attributes: [],
                box: [0.1, 0.2, 0.3, 0.4],
                region: [0.0, 0.0, 1.0, 1.0],
                score: 0.95,
                top_score: 0.98,
                type: "object"
            ),
            box: nil,
            false_positive: nil,
            plus_id: nil,
            retain_indefinitely: false,
            sub_label: nil,
            top_score: nil
        ))
    }
}
