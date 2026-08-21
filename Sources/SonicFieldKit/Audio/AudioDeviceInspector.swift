import Foundation
import CoreAudio
import AVFoundation

/// Struct representing detailed information about an audio input device discovered via Core Audio.
public struct AudioDeviceInfo: Sendable, Identifiable, Codable {
    public let id: UInt32
    public let uid: String
    public let name: String
    public let manufacturer: String
    public let isDefaultInput: Bool
    public let isBuiltInMic: Bool
    public let inputChannelCount: Int
    public let sampleRate: Double
    public let formatDescription: String
    public let channelDescriptions: [String]
}

/// Discovers audio hardware devices, stream formats, and physical channel layouts using Core Audio C APIs.
public final class AudioDeviceInspector: @unchecked Sendable {
    public static let shared = AudioDeviceInspector()

    public init() {}

    /// Enumerates all audio input devices currently available on macOS.
    public func discoverInputDevices() -> [AudioDeviceInfo] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        guard status == noErr, propertySize > 0 else {
            return []
        }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        let getStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )

        guard getStatus == noErr else { return [] }

        let defaultInputID = getDefaultInputDeviceID()

        var devices: [AudioDeviceInfo] = []
        for deviceID in deviceIDs {
            let channelCount = getInputChannelCount(deviceID: deviceID)
            if channelCount > 0 {
                let name = getDeviceName(deviceID: deviceID)
                let uid = getDeviceUID(deviceID: deviceID)
                let manufacturer = getDeviceManufacturer(deviceID: deviceID)
                let sampleRate = getDeviceSampleRate(deviceID: deviceID)
                let formatDesc = getDeviceStreamFormatDescription(deviceID: deviceID)
                let isBuiltIn = uid.contains("BuiltInMicrophoneDevice") || name.lowercased().contains("built-in") || name.lowercased().contains("macbook")
                let isDefault = (deviceID == defaultInputID)
                let chDescs = getChannelDescriptions(deviceID: deviceID, channelCount: channelCount)

                let info = AudioDeviceInfo(
                    id: deviceID,
                    uid: uid,
                    name: name,
                    manufacturer: manufacturer,
                    isDefaultInput: isDefault,
                    isBuiltInMic: isBuiltIn,
                    inputChannelCount: channelCount,
                    sampleRate: sampleRate,
                    formatDescription: formatDesc,
                    channelDescriptions: chDescs
                )
                devices.append(info)
            }
        }

        return devices
    }

    /// Finds the Built-in Microphone info, or falls back to the default input device.
    public func getBuiltInOrDefaultMicrophone() -> AudioDeviceInfo? {
        let devices = discoverInputDevices()
        if let builtIn = devices.first(where: { $0.isBuiltInMic }) {
            return builtIn
        }
        return devices.first(where: { $0.isDefaultInput }) ?? devices.first
    }

    // MARK: - Core Audio C-API Property Helpers

    private func getDefaultInputDeviceID() -> AudioDeviceID {
        var defaultID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultID
        )
        return defaultID
    }

    private func getInputChannelCount(deviceID: AudioDeviceID) -> Int {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize)
        guard status == noErr, propertySize > 0 else { return 0 }

        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))
        defer { bufferListPointer.deallocate() }

        let getStatus = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, bufferListPointer)
        guard getStatus == noErr else { return 0 }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferListPointer)
        var totalChannels = 0
        for buffer in buffers {
            totalChannels += Int(buffer.mNumberChannels)
        }
        return totalChannels
    }

    private func getDeviceName(deviceID: AudioDeviceID) -> String {
        return getStringProperty(deviceID: deviceID, selector: kAudioObjectPropertyName) ?? "Unknown Device"
    }

    private func getDeviceUID(deviceID: AudioDeviceID) -> String {
        return getStringProperty(deviceID: deviceID, selector: kAudioDevicePropertyDeviceUID) ?? "Unknown UID"
    }

    private func getDeviceManufacturer(deviceID: AudioDeviceID) -> String {
        return getStringProperty(deviceID: deviceID, selector: kAudioObjectPropertyManufacturer) ?? "Apple Inc."
    }

    private func getStringProperty(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var stringRef: CFString? = nil
        var propertySize = UInt32(MemoryLayout<CFString?>.size)

        let status = withUnsafeMutablePointer(to: &stringRef) { ptr in
            AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, ptr)
        }

        if status == noErr, let string = stringRef {
            return string as String
        }
        return nil
    }

    private func getDeviceSampleRate(deviceID: AudioDeviceID) -> Double {
        var sampleRate: Float64 = 0
        var propertySize = UInt32(MemoryLayout<Float64>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &sampleRate)
        return (status == noErr) ? Double(sampleRate) : 48000.0
    }

    private func getDeviceStreamFormatDescription(deviceID: AudioDeviceID) -> String {
        var asbd = AudioStreamBasicDescription()
        var propertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamFormat,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &asbd)
        guard status == noErr else { return "Float32 (32-bit float)" }

        let sampleRateInt = Int(asbd.mSampleRate)
        let channels = asbd.mChannelsPerFrame
        let formatFlags = asbd.mFormatFlags
        let isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0

        let typeStr = isFloat ? "Float32" : "Int\(asbd.mBitsPerChannel)"
        return "\(typeStr) pcm, \(sampleRateInt) Hz, \(channels) ch"
    }

    private func getChannelDescriptions(deviceID: AudioDeviceID, channelCount: Int) -> [String] {
        var descs: [String] = []
        for i in 1...channelCount {
            descs.append("Channel \(i)")
        }
        return descs
    }
}
