//
//  ControlPanel.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/20/24.
//

import SwiftUI
import RealityKit

/// A simple horizontal view presenting the user with video playback controls.
public struct ControlPanel: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    /// The callback to execute when the user closes the immersive player.
    let closeAction: CustomAction?
    
    /// Custom buttons provided by the developer.
    let customButtons: CustomViewBuilder?
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the binding to the singleton video player control interface.
    ///   - closeAction: the optional callback to execute when the user closes the immersive player.
    ///   - customButtons: an optional view builder for custom buttons to add to the left of the MediaInfo.
    public init(videoPlayer: Binding<VideoPlayer>, closeAction: CustomAction? = nil, customButtons: CustomViewBuilder? = nil) {
        self._videoPlayer = videoPlayer
        self.closeAction = closeAction
        self.customButtons = customButtons
    }
    
    public var body: some View {
        if videoPlayer.shouldShowControlPanel {
            VStack(alignment: .trailing) {
                // Hidden view above the control panel that can reveal to show additional options
                if videoPlayer.shouldShowPlaybackOptions {
                    VariantSelector(videoPlayer: $videoPlayer)
                        .transition(.scale(0, anchor: .trailing))
                        .frame(minHeight: 0, alignment: .bottom)
                        .padding()
                }
                
                VStack {
                    HStack {
                        Button("", systemImage: "chevron.backward") {
                            closeAction?()
                        }
                        .controlSize(.extraLarge)
                        .tint(.clear)
                        .frame(width: 100)
                        
                        if let customButtons {
                            AnyView(customButtons($videoPlayer))
                        }
                        
                        MediaInfo(videoPlayer: $videoPlayer)
                    }
                    
                    HStack {
                        PlaybackButtons(videoPlayer: videoPlayer)
                        
                        Scrubber(videoPlayer: $videoPlayer)
                        
                        TimeText(videoPlayer: videoPlayer)
                    }
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
    }
}

/// A simple horizontal view with a dark background presenting video title, description, and a bitrate readout.
public struct MediaInfo: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the binding to the singleton video player control interface.
    public init(videoPlayer: Binding<VideoPlayer>) {
        self._videoPlayer = videoPlayer
    }
    
    public var body: some View {
        ZStack(alignment: .trailing) {
            // Video title and details text
            VStack {
                Text(videoPlayer.title)
                    .font(.title)
                
                Text(videoPlayer.details)
                    .font(.headline)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 120)
            .padding(.vertical)
            .truncationMode(.tail)
            
            if videoPlayer.canChooseResolution || videoPlayer.canChooseAudio {
                ResolutionToggle(videoPlayer: $videoPlayer)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, maxHeight: CGFloat(Config.shared.controlPanelMediaInfoMaxHeight))
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.black.opacity(0.5))
        .cornerRadius(30)
    }
}

/// A toggle to control the visibility of the `ResolutionSelector`
public struct ResolutionToggle: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the binding to the singleton video player control interface.
    public init(videoPlayer: Binding<VideoPlayer>) {
        self._videoPlayer = videoPlayer
    }
    
    public var body: some View {
        let config = Config.shared
        let showResolutionOptions = Binding<Bool>(
            get: { videoPlayer.shouldShowPlaybackOptions },
            set: { _ in videoPlayer.togglePlaybackOptions() }
        )
        let showBitrate = config.controlPanelShowBitrate && videoPlayer.bitrate > 0
        
        VStack {
            Toggle("", systemImage: "gearshape.fill", isOn: showResolutionOptions)
            .toggleStyle(.button)
            
            if showBitrate {
                BitrateReadout(videoPlayer: videoPlayer)
            }
        }
        .frame(width: 100)
    }
}

/// A colored text view presenting the user with the current video stream's bitrate.
public struct BitrateReadout: View {
    /// The singleton video player control interface.
    var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the singleton video player control interface.
    public init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
    }
    
    public var body: some View {
        let textColor = color(for: videoPlayer.bitrate, ladder: videoPlayer.resolutionOptions)
            .opacity(0.8)
        
        Text("\(videoPlayer.bitrate/1_000_000, specifier: "%.1f") Mbps")
            .frame(width: 100)
            .font(.caption.monospacedDigit())
            .foregroundStyle(textColor)
    }

    /// Evaluates the font color for the bitrate label depending on bitrate value.
    /// - Parameters:
    ///   - bitrate: the bitrate value as a `Double`
    ///   - ladder: the resolution options for the stream
    ///   - tolerance: the tolerance for color threshold (default 1.2Mbps)
    /// - Returns: White if top bitrate for the stream, yellow if second best, orange if third best, red otherwise.
    private func color(for bitrate: Double, ladder options: [ResolutionOption], tolerance: Int = 1_200_000) -> Color {
        if options.count > 3 && bitrate < Double(options[2].bitrate - tolerance) {
            .red
        } else if options.count > 2 && bitrate < Double(options[1].bitrate - tolerance) {
            .orange
        } else if options.count > 1 && bitrate < Double(options[0].bitrate - tolerance) {
            .yellow
        } else {
            .white
        }
    }
}


/// A simple horizontal view presenting the user with video playback control buttons.
public struct PlaybackButtons: View {
    /// The singleton video player control interface.
    var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the singleton video player control interface.
    public init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
    }
    
    public var body: some View {
        HStack {
            Button("", systemImage: "gobackward.15") {
                videoPlayer.minus15()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
            
            if videoPlayer.paused {
                Button("", systemImage: "play") {
                    videoPlayer.play()
                }
                .controlSize(.extraLarge)
                .tint(.clear)
                .frame(width: 100)
            } else {
                Button("", systemImage: "pause") {
                    videoPlayer.pause()
                }
                .controlSize(.extraLarge)
                .tint(.clear)
                .frame(width: 100)
            }
            
            Button("", systemImage: "goforward.15") {
                videoPlayer.plus15()
            }
            .controlSize(.extraLarge)
            .tint(.clear)
            .frame(width: 100)
        }
    }
}

/// A video scrubber made of a slider, which uses a simple state machine contained in `videoPlayer`.
/// Allows users to set the video to a specific time, while otherwise reflecting the current position in playback.
public struct Scrubber: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    let config = Config.shared
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the binding to the singleton video player control interface.
    public init(videoPlayer: Binding<VideoPlayer>) {
        self._videoPlayer = videoPlayer
    }
    
    public var body: some View {
        Slider(value: $videoPlayer.currentTime, in: 0...videoPlayer.duration) { scrubbing in
            if scrubbing {
                videoPlayer.scrubState = .scrubStarted
            } else {
                videoPlayer.scrubState = .scrubEnded
            }
        }
        .controlSize(.extraLarge)
        .tint(config.controlPanelScrubberTint)
        .background(Color.white.opacity(0.5), in: .capsule)
        .padding()
    }
}

/// A label view printing the current time and total duration of a video.
public struct TimeText: View {
    /// The singleton video player control interface.
    var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the singleton video player control interface.
    public init(videoPlayer: VideoPlayer) {
        self.videoPlayer = videoPlayer
    }
    
    public var body: some View {
        Text(timeString)
            .font(.headline)
            .monospacedDigit()
            .frame(width: frameWidth)
    }
    
    /// The string representation of the current playback time and duration of the `VideoPlayer`'s current media.
    ///
    /// If the duration is greater than one hour, the string representation shows hours.
    var timeString: String {
        guard videoPlayer.duration > 0 else {
            return "--:-- / --:--"
        }
        let timeFormat: Duration.TimeFormatStyle = videoPlayer.duration >= 3600 ? .time(pattern: .hourMinuteSecond) : .time(pattern: .minuteSecond)
        
        let currentTime = Duration
            .seconds(videoPlayer.currentTime)
            .formatted(timeFormat)
        let duration = Duration
            .seconds(videoPlayer.duration)
            .formatted(timeFormat)
        
        return "\(currentTime) / \(duration)"
    }
    
    var frameWidth: CGFloat {
        get {
            if videoPlayer.duration >= 36_000 {
                return 200
            }
            if videoPlayer.duration >= 3600 {
                return 180
            }
            return 150
        }
    }
}

/// A row of buttons to select the resolution / quality of the video stream.
public struct VariantSelector: View {
    /// The singleton video player control interface.
    @Binding var videoPlayer: VideoPlayer
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - videoPlayer: the binding to the singleton video player control interface.
    public init(videoPlayer: Binding<VideoPlayer>) {
        self._videoPlayer = videoPlayer
    }
    
    public var body: some View {
        VStack(alignment: .trailing) {
            if videoPlayer.canChooseAudio {
                let options = videoPlayer.audioOptions
                let zippedOptions = Array(zip(options.indices, options))
                let isOn: (Int) -> Binding<Bool> = { index in
                    Binding {
                        videoPlayer.selectedAudioIndex == index
                    } set: { _ in
                        videoPlayer.openAudioOption(index: index)
                    }
                }
                
                HStack {
                    Toggle(isOn: isOn(-1)) {
                        Text("Default")
                            .font(.headline)
                    }
                    .toggleStyle(.button)
                    
                    ForEach(zippedOptions, id: \.0) { index, option in
                        Toggle(isOn: isOn(index)) {
                            VStack(spacing: -3) {
                                Text(option.description)
                                    .font(.caption)
                                
                                Text(option.groupId.capitalized)
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                            .padding(.vertical, -5)
                        }
                        .toggleStyle(.button)
                    }
                }
            }
            
            if videoPlayer.canChooseResolution {
                let options = videoPlayer.resolutionOptions
                let zippedOptions = Array(zip(options.indices, options))
                let isOn: (Int) -> Binding<Bool> = { index in
                    Binding {
                        videoPlayer.selectedResolutionIndex == index
                    } set: { _ in
                        videoPlayer.openResolutionOption(index: index)
                    }
                }
                
                HStack {
                    Toggle(isOn: isOn(-1)) {
                        Text("Auto")
                            .font(.headline)
                    }
                    .toggleStyle(.button)
                    
                    ForEach(zippedOptions, id: \.0) { index, option in
                        Toggle(isOn: isOn(index)) {
                            Text(option.resolutionString)
                                .font(.subheadline)
                            Text(option.bitrateString)
                                .font(.caption)
                                .opacity(0.8)
                        }
                        .toggleStyle(.button)
                    }
                }
            }
        }
        
    }
}

//#Preview(windowStyle: .automatic, traits: .fixedLayout(width: 1200, height: 45)) {
//    ControlPanel(videoPlayer: .constant(VideoPlayer()))
//}

#Preview {
    RealityView { content, attachments in
        if let entity = attachments.entity(for: "ControlPanel") {
            content.add(entity)
        }
    } attachments: {
        Attachment(id: "ControlPanel") {
            ControlPanel(videoPlayer: .constant(VideoPlayer()))
        }
    }
}
