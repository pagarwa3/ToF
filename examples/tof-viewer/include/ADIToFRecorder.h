/********************************************************************************/
/*                                                                              */
/* Copyright (c) 2020 Analog Devices, Inc. All Rights Reserved.                 */
/* This software is proprietary to Analog Devices, Inc. and its licensors.      */
/*                                                                              */
/********************************************************************************/
#ifndef ADITOFRECORDER_H
#define ADITOFRECORDER_H

#include "safequeue.h"
#include <aditof/frame.h>
#include <atomic>
#include <fstream>
#include <functional>
#include <map>
#include <thread>

#ifdef _WIN32
#include <direct.h>
#endif

class ADIToFRecorder {

  public:
    /**
	* @brief ADI Recorder constructor
	*/
    ADIToFRecorder();

    /**
	* @brief ADI Recorder destructor
	*/
    ~ADIToFRecorder();

    /**
	* @brief			Start the recording thread
	* @param fileName	Given file name by the user
	* @param height		Image height, set by SDK
	* @param width		Image width, set by SDK
	* @param fps		Number of frames set by the user
	*/
    void startRecording(const std::string &fileName, unsigned int height,
                        unsigned int width, unsigned int fps);

    /**
    * @brief           Start RAW fileformat recording
    * @param fileName	Given file name by the user
    * @param height		Image height, set by SDK
    * @param width		Image width, set by SDK
    * @param fps		Number of frames set by the user
    */
    void startRecordingRaw(const std::string &fileName, unsigned int height,
                           unsigned int width, unsigned int fps);

    /**
	* @brief Stops Recording
	*/
    void stopRecording();

    /**
	* @brief			Starts raw playback
	* @param fileName	Given file name by the user
	* @param fps		Number of frames set by the user
	*/
    int startPlayback(const std::string &fileName, int &fps);

    /**
	* @brief			Starts ADI's raw playback
	* @param fileName	Given file name by the user
	* @param fps		Number of frames set by the user
	*/
    int startPlaybackRaw(const std::string &fileName, int &fps);

    /**
	* @brief Stop playback
	*/
    void stopPlayback();

    /**
	* @brief Recording new frame
	*/
    void recordNewFrame(std::shared_ptr<aditof::Frame> frame);

    /**
	* @brief Start reading new frame
	*/
    std::shared_ptr<aditof::Frame> readNewFrame();

    /**
	* @brief Request Frame
	*/
    void requestFrame();

    /**
	* @brief Gets Recording enabled flag
	*/
    bool isRecordingEnabled() const;

    /**
	* @brief Gets playback enabled flag
	*/
    bool isPlaybackEnabled() const;

    /**
	* @brief Gets playback EOF flag
	*/
    bool isPlaybackFinished() const;

    /**
	* @brief Gets recording finished flag
	*/
    bool isRecordingFinished() const;

    /**
	* @brief Gets playback paused flag
	*/
    bool isPlaybackPaused();

    /**
	* @brief Sets playback paused flag
	*/
    void setPlaybackPaused(bool paused = true);

    /**
	* @brief Gets number of frames
	*/
    int getNumberOfFrames() const;
    std::shared_ptr<aditof::Frame> playbackFrame;

    /**
	* @brief Record ADI's Raw Data
	*/
    void recordThread();

    /**
	* @brief ADIs RAW Playback Thread
	*/
    void playbackThread();

    /**
	* @brief Clears all playback and recording variables
	*/
    void clearVariables();

    /**
	* @brief Will build XYZ stream
	*/
    void processXYZData();

  private:
    /**
	* @brief Analyzes the given number and returns its number
	*        of digits.
	*/
    int findDigits(int number);

    /**
     * @brief                   Create binary directory
     * @param  fileDirectory    String with full path for saved raw file
     * 
     */
    void createBinaryDirectory(std::string fileName);

  public:
    uint16_t *frameDataLocationDEPTH = nullptr;
    uint16_t *frameDataLocationXYZ = nullptr;
    uint16_t *frameDataLocationIR = nullptr;
    uint16_t *frameDataLocationHeader = nullptr;
    aditof::FrameDetails m_frameDetails;
    bool m_saveBinaryFormat = false;
    bool m_finishRecording = true;
    bool _stopPlayback = false;
    int currentPBPos = 0;
    int m_numberOfFrames;
    int fileSize = 0;
    uint16_t m_sizeOfHeader;

  private:
    SafeQueue<std::shared_ptr<aditof::Frame>> m_playbackQueue;
    SafeQueue<std::shared_ptr<aditof::Frame>> m_recordQueue;
    std::ofstream m_recordFile;
    //Raw stream
    std::atomic<bool> m_playbackThreadStop;
    std::atomic<bool> m_recordTreadStop;
    std::condition_variable m_playbackCv;
    std::thread m_playbackThread;
    std::ifstream m_playbackFile;
    std::string m_fileNameRaw;
    std::thread m_recordThread;
    std::mutex m_playbackMutex;
    bool m_shouldReadNewFrame;
    bool m_playBackEofReached;
    bool isPaused = false;
    int framesToRecord = 0;
    const int _depth = 2;
    const int _ir = 1;
    size_t frameCtr = 0;
};

#endif // ADITOFRECORDER_H
