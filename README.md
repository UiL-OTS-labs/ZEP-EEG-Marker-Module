# ZEP-Markers-Module

This [Zep](https://www.beexy.nl/zep/wiki/doku.php) module provides a way to send markers (i.e. triggers) from your Zep experiment using a parallel port. For instance you can send triggers from an EEG experiment to the BioSemi USB receiver.

Markers are setup sometime before their required onset. The timers can hold one marker at a time. Hence, if you set up markers in sequence the scheduler will plan to transfer them to the timers milliseconds before their onset. In this way the scheduler limits the frequency you can send markers at. This limit (using default settings) is ~133 Hz (or at 7.5ms intervals).

## Requirements for this module
*   [Zep version 2.0.9 or later](https://beexy.nl/zep2/wiki/doku.php?id=get_zep)
*   A parallel port (either via a PCIe peripheral or directoy from the motherboard).

## How to use this module
1.  Copy the files `zep_markers.zm` and `zep_markers_settings.zm` from this repository to a location found by your experiment (_e.g._ your experiment's `/modules` directory).
2.  Within your experiment import the module by adding `import zep_markers;` to
the top of your `.zp` file.
3.  Within your experiment script, after setting up the presentation of a
stimulus add the following function call:

    `setup_marker_at(<int marker>, <time tref>);`

    With _marker_ being the integer you want to send and _tref_ set to the _expected_start_time_ of the stimulus that has been set up.
4.  Alternatively, you might want to send a marker as quickly as possible. Use the following function call for that:

    `send_marker(<int marker>);`

    This will set up a marker to be sent as quickly as possible. Because of internal logistics there is a minimum setup time for the marker. This setup is determined by the sum of `SCHEDULER_PRE_EMPT` and `SCHEDULER_PRE_EMPT_ERROR_TOLERANCE` settings. Using default settings this time is approx. 7.5ms.

## Temporal Performance of Module
There is a very short delay between the requested marker onset and the actual marker onset. On internal lab systems this delay was around 15 and 18 microseconds.

Using audio the most crucial timing statistic is the variability of delay between marker onset and audio onset. Below we compared Presentation(c) audio-trigger delay with that of Zep using this marker module.

The results have an accuracy of 10 microseconds (0.010 milliseconds). Zep 2.0 was run under Kubuntu 16.04 and Presentation under Windows 10. Both used the front channels on the creative sound blaster Audigy 5/Rx and using a PCIe-based parallel port. The test were furthermore done using a Teensy with custom firmware to monitor both the audio and trigger line. Statistics are based on a 1000 sampled epochs per sample rate and software implementation. The sound file was a 16bit WAV at 44.1kHz with a 10ms 2kHz sine wave. 


| Software     | Soundcard Mode (Hz) | Mean (ms) | Std. Deviation (ms) | Min (ms) | Max (ms) | Range (ms) |
|--------------|-----------------|-----------|---------------------|----------|----------|------------|
| Presentation(c) | 44100           | 1.04      | 0.01                | 0.98     | 1.06     | 0.08       |
| Zep 2.0          | 44100           | 1.61      | 0.01                | 1.58     | 1.65     | 0.07       |
| Presentation(c) | 48000           | 0.81      | 0.04                | 0.73     | 0.90     | 0.17       |
| Zep 2.0          | 48000           | 1.53      | 0.01                | 1.50     | 1.55     | 0.05       |

Zep performed best when using the soundcard in the 48kHz mode; the Range and Std. Deviation were the lowest in this mode.

## Development mode
When you don't have a parallel port available you can still test and integrate this module by setting `DEVELOP_MODE` to true in `zep_markers_settings.zm`.

`const bool DEVELOP_MODE = true;`

This makes the module work without a parallel port but only simulates sending output. It might be a good idea to swith off of this mode when doing the actual experiment.

## Logs
The module logs the status of markers in a date-formatted file in the `./logs` directory. It logs both the failed (timing / validation) and successful markers.

## Troubleshooting
Below are some common problems and their solutions. If these do not work please ask your technician for help. Make sure you run the experiment in such a way you can see the error output of Zep. This module outputs _WARNINGS_ and _ERRORS_ that might explain trouble.

### Module cannot find the device or connects to wrong device

#### Check the `PORT_NUMBER`
Sometimes the parallel port you want is not the first one your system has found.
By default the port number is set to `0`. You can change the port number setting the `PORT_NUMBER` variable at the top of the `zep_markers_settings.zm` file.


### Warnings when sending more than one marker simultaneously
    `!! WARNING - Marker 5's onset conflicts with a marker (4) that has already been scheduled !!`
Sending two markers simultaneously is not possible. A marker consists of a pulse-up and a pulse-down phase. The interval between up and down is the pulse length or duration. During this pulse we are sending a marker and another cannot start. The pulse _down_ needs to finish before a pulse _up_ can start. Hence there is a minimal pause between two marker onsets. By default this pause is the pulse length of the first marker plus some scheduling time. The module uses a scheduler that requires extra time for planning and setup the marker data. This extends the actual required time for a marker.

For instance, if the marker' `pulse_length` is 20ms and the `SCHEDULER_PRE_EMPT` setting is 5ms (default) the marker requires a minimum time-window of 25ms. Within this 25ms period no other markers can be set.

The solution is to redesign your experiment so sending two or more markers at nearly the same time does not happen.

### Overloading the scheduler
    `!! ERROR Overloading - Marker 9 failed to be pre-empted on time (1287.166ms too late) !!`
    `!! ERROR Overloading - Marker 1 failed to be scheduled to pre-empt on time (294.923ms too late) !!`

The scheduler fires slightly before the onset timing of an marker. When the scheduler fires (i.e. _expires_) it needs some CPU time to pre-emptively transfer the marker to the timers. If the transfer does not occur on time the scheduler is considered _being overloaded_. This overload can result in a cascade of failed markers.

The solution is to lighten the load on the CPU during crucial and marked parts of your experiment. For instance, try to shuffle at the start of the experiment instead of at the start of a trial.

### The timing of the markers in the recording varies too much
Make sure you avoid using `send_marker()`. Use `send_marker()` if you want to insert a marker and care nothing for the accuracy of timing.

Try to use `setup_marker_at()` with the _expected_start_time_ of your stimulus object.
If using this function creates variation creates jitter something might be wrong with the way you set up the stimulus objects. Make sure you check for discrepancies between the _expected_start_time_ and the actual _start_time_ of you stimulus objects.

Note that the scheduler has some tolerance for scheduling-timing variance when sending the marker to the marker-sending device. The actual marker time is unaffected when the variance falls within this tolerance.

### EEG recordings with ActiView (Biosemi Software) suddenly pauses for no good reason
ActiView can be [configured](https://www.biosemi.com/faq/trigger_signals.htm) to start a pause or stop a pause on specific markers.
Check the .cfg you feed ActiView for the following:

     Example of .cfg text:
     PauseOff="254 //-1 is disabled, 0-255 is enabled"
     PauseOn="255 //-1 is disabled, 0-255 is enabled"
