//
//  RecordScreenViewController.swift
//  finalproject
//
//  Created by Diya on 12/4/23.
//

import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseStorage

class RecordScreenViewController: UIViewController, AVAudioRecorderDelegate {
    
    let recordView = RecordScreenView()
    
    var currentUser: FirebaseAuth.User?
    let storageRef = Storage.storage().reference()
    
    var audioRecorder: AVAudioRecorder?
    var audioFileName: URL?
    var recordingSession: AVAudioSession!
    
    var recordingList: [Recording] = []
    
    override func loadView() {
        view = recordView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Audio Moments"
        
        setupAudioRecorder()
        
        recordView.recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        
        recordView.tableViewRecordings.delegate = self
        recordView.tableViewRecordings.dataSource = self
        
        fetchRecordings()
    }
    
    @objc private func recordButtonTapped() {
        print("Record button tapped")

        if let recorder = audioRecorder {
                if recorder.isRecording {
                    // Stop recording
                    recorder.stop()
                    finishRecording(success: true) // Assuming it's a success if stopped
                } else {
                    // Start recording
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        recorder.record()
                        recordView.recordButton.setTitle("Recording...", for: .normal)
                    } catch {
                        print("Error starting recording: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    func setupAudioRecorder() {
        print("setup audio recorder")
        // Create and configure the recording session
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        // No need to load recording UI here
                    } else {
                        // Handle the case where recording permission is denied
                        // You might want to show an alert or take appropriate action
                    }
                }
            }

            // Set up audio recorder
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFileName = documentsDirectory.appendingPathComponent("audioRecording.m4a")

            audioRecorder = try AVAudioRecorder(url: audioFileName!, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            print("Error setting up audio recorder: \(error.localizedDescription)")
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }

    func finishRecording(success: Bool) {
        
        print("finish recording")
        audioRecorder?.stop()
        audioRecorder = nil

        if success {
//            recordView.recordButton.setTitle("Tap to Re-record", for: .normal)
            uploadRecordingToStorage()
            
        } else {
            print("recording failed")
//            recordView.recordButton.setTitle("Tap to Record", for: .normal)
        }
    }

}
