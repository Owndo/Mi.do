import AVFoundation
import Foundation
import Speech
import NaturalLanguage
import DateManager
import TelemetryManager
import MagicManager

@Observable
public final class RecorderManager: RecorderManagerProtocol, @unchecked Sendable {
    private var telemetryManager: TelemetryManagerProtocol
    
    private var titleExtractor: MagicManager
    private var avAudioRecorder: AVAudioRecorder?
    
    private var baseDirectoryURL: URL = FileManager.default.temporaryDirectory
    
    public var timer: Timer?
    public var currentlyTime = 0.0
    public var progress = 0.00
    public var maxDuration = 15.00
    public var decibelLevel: Float = 0.0
    public var isRecording = false
    
    private var previousDecibelLevel: Float = 0.0
    
    // MARK: - Speech Recognition Properties
    public var recognizedText = ""
    public var dateTimeFromtext: Date?
    public var wholeDescription: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    public let setting: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]
    
    public var fileName: URL?
    
    private init(dateManager: DateManagerProtocol) {
        self.telemetryManager = TelemetryManager.createTelemetryManager()
        titleExtractor = MagicManager.createMagicManager(dateManager: dateManager)
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    }
    
    //MARK: - Manager creator
    
    public static func createRecorderManager(dateManager: DateManagerProtocol) -> RecorderManagerProtocol {
        return RecorderManager(dateManager: dateManager)
    }
    
    //MARK: - Create MockManager
    
    public static func createMock() -> RecorderManagerProtocol {
        return RecorderManager(dateManager: DateManager.createEmptyManager())
    }
    
    // MARK: - Start recording with speech recognition
    public func startRecording() async {
        let fileName = baseDirectoryURL.appending(path: "\(UUID().uuidString).wav")
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers])
            try session.setActive(true)
            
            avAudioRecorder = try AVAudioRecorder(url: fileName, settings: setting)
            avAudioRecorder?.prepareToRecord()
            avAudioRecorder?.isMeteringEnabled = true
            avAudioRecorder?.record()
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            isRecording = avAudioRecorder?.isRecording ?? false
            
            startSpeechRecognition()
            
            await updateTime()
            self.fileName = fileName
            
        } catch {
            print("Couldn't create AVAudioRecorder: \(error)")
        }
    }
    
    public func clearFileFromDirectory() {
        guard let file = fileName else {
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Error while clearing temporary directory: \(error)")
        }
    }
    
    // MARK: - Stop recording and speech recognition
    public func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        avAudioRecorder?.stop()
        avAudioRecorder?.isMeteringEnabled = false
        
        avAudioRecorder = nil
        
        stopSpeechRecognition()
        
        progress = 0.0
        currentlyTime = 0.0
        isRecording = avAudioRecorder?.isRecording ?? false
        
        if let fileName = fileName {
            return fileName
        } else {
            return nil
        }
    }
    
    // MARK: - Speech Recognition Methods
    
    private func startSpeechRecognition() {
        let status = SFSpeechRecognizer.authorizationStatus()
        
        guard status == .authorized else {
            return
        }
        
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            return
        }
        
        do {
            let (audioEngine, request) = try prepareEngineForSpeechRecognition()
            self.audioEngine = audioEngine
            self.recognitionRequest = request
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                self?.handleSpeechRecognitionResult(result: result, error: error)
            }
        } catch {
            print("Failed to start speech recognition: \(error)")
        }
    }
    
    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        wholeDescription = recognizedText
        
        dateTimeFromtext = titleExtractor.extractDateTime(from: recognizedText)?.date
        recognizedText = titleExtractor.extractTaskTitleWithNames(from: recognizedText)
        
        if recognizedText == "New task" {
            recognizedText = ""
        }
        
        if !recognizedText.isEmpty {
            telemetryManager.logEvent(.taskAction(.filledTitle))
        }
        
        if dateTimeFromtext != nil {
            telemetryManager.logEvent(.taskAction(.filledDate))
        }
    }
    
    public func resetDataFromText() {
        recognizedText = ""
        dateTimeFromtext = nil
    }
    
    private func prepareEngineForSpeechRecognition() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func handleSpeechRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            Task { @MainActor in
                recognizedText = result.bestTranscription.formattedString
            }
        }
        
        if let error = error {
            print("Speech recognition error: \(error)")
        }
    }
    
    // MARK: - Check and update recording time
    private func updateTime() async {
        Task { @MainActor in
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.currentlyTime = self.avAudioRecorder?.currentTime ?? 00
                self.progress = (self.currentlyTime / self.maxDuration)
                self.updateDecibelLvl()
            }
        }
    }
    
    // MARK: - Functions for get and showing decibel LVL
    private func updateDecibelLvl() {
        guard let recorder = avAudioRecorder else {
            return
        }
        
        recorder.updateMeters()
        let decibelLevel = recorder.averagePower(forChannel: 0)
        
        let mappedValue = mapDecibelLessNoiseSensitive(dB: decibelLevel)
        
        let inertiaFactor: Float = 0.5
        let smoothedValue = previousDecibelLevel * inertiaFactor + mappedValue * (1 - inertiaFactor)
        
        self.decibelLevel = smoothedValue
        self.previousDecibelLevel = smoothedValue
    }
    
    private func mapDecibelLessNoiseSensitive(dB: Float, minDcb: Float = -80, maxDcb: Float = 0, minRange: Float = 0.0, maxRange: Float = 1.5) -> Float {
        let clampedDB = max(min(dB, maxDcb), minDcb)
        
        let normalizedDB = (clampedDB - minDcb) / (maxDcb - minDcb)
        
        let power: Float = 1.5
        let correctedValue = pow(normalizedDB, power)
        
        let noiseThreshold: Float = 0.1
        let noiseSuppressedValue = correctedValue < noiseThreshold ? 0 : correctedValue
        
        let result = minRange + noiseSuppressedValue * (maxRange - minRange)
        return result
    }
    
    deinit {
        stopSpeechRecognition()
    }
}
