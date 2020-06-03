# Strucc-Challenge

## Overview

The app is broken up into 2 parts. A recording part, and a preview part. Files for each can be found in their respective folders. The 2 parts communicate the assets (the recorded video), through the user's tmp file directory where the 2 mp4 video files the user recorded are stored. The first part writes to these files, and the second part reads them

### Recording

There are 3 classes here.

The RecordingViewController which handles the view and mediates some logic between the rest of the classes. The RecordingManager which handles the camera and the asset writing. And a RecordingButtonView, which work as a regular button telling the RecordingViewController when to begin the recording and when to stop the recording.

Pretty much all the business logic resides in the RecordingManager. It sets up a capture session and asset writers responding to commands from the RecordingViewController such as when to start/stop/pause the capture session and start/stop the recording using the available asset writer. Inversely, the RecordingManager communicates any errors and relevant status updates to the RecordingViewController through its delegate so it can  can act accordingly.

The capture session is setup with the 1920x1080 video preset and connects the best available cameras to itself. The output object attached to the capture session is an AVCaptureVideoDataOutput making it easy to use the asset writers with it and opening up more possiblities for the video feed preview down the road. There is no custom preview layer, the standard AVCaptureVideoPreviewLayer is used.

The asset writer is setup to write the recorded video to the user's temp directory in a standard mp4 format.

### Preview

There are 6 classes here (5 files). The communication structure is the same as for the recording.

The PreviewViewController handles the view and mediating some logic between the rest of the classes. The PreviewManager which handles creating the composition and returning the preview layer. A FilterCarouselView class which is a carousel view and works off of a FilterModel input. The FilterModel represents the filters to display. A CustomCompositor (AVVideoCompositing subclass) to apply the intended effects to the video composition. And finally there's a singleton which the manager updates so that the custom compositor can know which filter to apply during it's runtime.

The compositon is done by building the assets for the videos from the user's tmp directory, adding the relevant tracks and then having them be processed by the custom compositor. The playback is handled by a simple AVPlayer.
