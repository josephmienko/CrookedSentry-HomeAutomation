import SwiftUI

struct EventCardView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    let event: FrigateEvent
    let isInProgress: Bool
    var isUnreviewed: Bool = false
    var onMarkAsReviewed: ((String) async -> Void)? = nil
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main event row
            HStack(alignment: .center, spacing: 16) {
                // Thumbnail with rounded corners (no badge here anymore)
                if let thumbnailUrl = event.thumbnailUrl(baseURL: settingsStore.frigateBaseURL) {
                    RemoteImage(url: thumbnailUrl) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceContainerHigh)
                            .frame(width: 80, height: 80)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    } content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceContainerHigh)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.onSurfaceVariant)
                        )
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    // Top line: "<<OBJECT>> seen in <<LOCATION>>"
                    HStack {
                        Text("\(event.friendlyLabelName) seen in \(event.friendlyCameraName)")
                            .font(.body)
                            .fontWeight(isUnreviewed ? .bold : .medium)
                            .foregroundColor(.onSurface)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Status badges in upper right corner
                        HStack(spacing: 8) {
                            // Unreviewed badge (6px filled dot)
                            if isUnreviewed {
                                Circle()
                                    .fill(Color.error)
                                    .frame(width: 6, height: 6)
                            }
                            
                            // In progress indicator
                            if isInProgress {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.error)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("Live")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.error)
                                }
                            }
                        }
                    }
                    
                    // Bottom line: "Recorded on <<TIME AND DATE STAMP>>, <<DURATION>><<DURATION_UNITS>>"
                    HStack {
                        Text("Recorded on \(Date(timeIntervalSince1970: event.start_time), formatter: detailedFormatter), \(formattedDuration)")
                            .font(.subheadline)
                            .foregroundColor(.onSurfaceVariant)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    // Zone information (if available)
                    if !event.zones.isEmpty {
                        Text("Zone: \(event.friendlyZoneNames)")
                            .font(.caption)
                            .foregroundColor(.onSurfaceVariant.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                // Ensure the text block is vertically centered relative to the thumbnail without
                // affecting internal line spacing. When the text is shorter than the thumbnail,
                // this keeps it centered; when it's taller, it expands naturally.
                .frame(minHeight: 80, alignment: .center)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.background)
            
            // Video section (expandable)
            if isExpanded && event.has_clip {
                VStack(spacing: 0) {
                    // Divider
                    Rectangle()
                        .fill(Color.outline.opacity(0.5))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    if let clipUrl = event.clipUrl(baseURL: settingsStore.frigateBaseURL) {
                        VideoPlayerView(
                            videoURL: clipUrl,
                            event: event,
                            baseURL: settingsStore.frigateBaseURL,
                            onDismiss: {
                                // No dismiss button needed - just close on tap
                            }
                        )
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .padding(16)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        Text("Video not available")
                            .font(.body)
                            .foregroundColor(.onSurfaceVariant)
                            .padding()
                    }
                }
                .background(Color.background)
            }
        }
        .background(Color.background)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .onTapGesture {
            if event.has_clip {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
                // If this is a completed event and we expand to play inline, mark it as reviewed
                if !isInProgress, event.end_time != nil, isExpanded {
                    if let onMarkAsReviewed = onMarkAsReviewed {
                        print("🧭 EventCardView: expanded inline video; marking as reviewed for id=\(event.id)")
                        Task { await onMarkAsReviewed(event.id) }
                    }
                }
            }
        }
    }
    
    private var formattedDuration: String {
        if let duration = event.duration {
            return durationFormatter.string(from: duration) ?? "0s"
        } else if isInProgress {
            let currentDuration = Date().timeIntervalSince1970 - event.start_time
            return durationFormatter.string(from: currentDuration) ?? "0s"
        } else {
            return "N/A"
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none // Removed date
        formatter.timeStyle = .medium
        return formatter
    }()
    
    private let detailedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    


}

struct EventCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode Preview
            VStack(spacing: 0) {
                EventCardView(event: FrigateEvent(
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
                ), isInProgress: false)
                .environmentObject(SettingsStore())
                
                Rectangle()
                    .fill(Color.outline)
                    .frame(height: 1)
                
                EventCardView(event: FrigateEvent(
                    id: "67890.1234-test",
                    camera: "back_yard",
                    label: "cat",
                    start_time: Date().timeIntervalSince1970 - 1800,
                    end_time: nil,
                    has_clip: true,
                    has_snapshot: true,
                    zones: ["garden"],
                    data: EventData(
                        attributes: [],
                        box: [0.2, 0.3, 0.4, 0.5],
                        region: [0.0, 0.0, 1.0, 1.0],
                        score: 0.88,
                        top_score: 0.91,
                        type: "object"
                    ),
                    box: nil,
                    false_positive: nil,
                    plus_id: nil,
                    retain_indefinitely: false,
                    sub_label: nil,
                    top_score: nil
                ), isInProgress: true)
                .environmentObject(SettingsStore())
            }
            .background(Color.background)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            // Dark Mode Preview
            VStack(spacing: 0) {
                EventCardView(event: FrigateEvent(
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
                ), isInProgress: false)
                .environmentObject(SettingsStore())
                
                Rectangle()
                    .fill(Color.outline)
                    .frame(height: 1)
                
                EventCardView(event: FrigateEvent(
                    id: "67890.1234-test",
                    camera: "back_yard", 
                    label: "cat",
                    start_time: Date().timeIntervalSince1970 - 1800,
                    end_time: nil,
                    has_clip: true,
                    has_snapshot: true,
                    zones: ["garden"],
                    data: EventData(
                        attributes: [],
                        box: [0.2, 0.3, 0.4, 0.5],
                        region: [0.0, 0.0, 1.0, 1.0],
                        score: 0.88,
                        top_score: 0.91,
                        type: "object"
                    ),
                    box: nil,
                    false_positive: nil,
                    plus_id: nil,
                    retain_indefinitely: false,
                    sub_label: nil,
                    top_score: nil
                ), isInProgress: true)
                .environmentObject(SettingsStore())
            }
            .background(Color.background)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
