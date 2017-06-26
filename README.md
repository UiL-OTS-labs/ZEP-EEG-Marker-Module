# ZEP-EEG-Marker-Module

This [Zep](https://www.beexy.nl/zep/wiki/doku.php) module provides a way to send markers (i.e. triggers) from your Zep experiment to a parallel input port.
One such input port is the USB receiver of the [BioSemi EEG equipment](https://www.biosemi.com/). This allows you to send markers with Zep! Yeah!

The modules uses an external [BeexyBox](https://www.beexy.nl/responseboxes/) which sends the actual markers. Markers (including their timings) are transferred to the BeexyBox sometimes before their required onset. The device can hold one marker at a time. Hence, if you set up markers in sequence the scheduler will plan to transfer them to the device milliseconds before their onset. The scheduler limits the frequency you can send markers at. This limit is ~40 Hz (or at 25ms intervals).

## Requirements for this module
*   [Zep version 2.0.9 or later](https://www.beexy.nl/zep/wiki/doku.php?id=download) or [eval version](https://beexy.nl/eval)
*   [BeexyBox type X](https://www.beexy.nl/responseboxes/)

## How to use this module
1.  Copy the file `eeg_markers.zm` from this repository to a location found by your experiment (_e.g._ your experiment's `/modules` directory).
2.  Within your experiment import the module by adding `import eeg_markers;` to
the top of your `.zp` file.
3.  Within your experiment script, after setting up the presentation of a
stimulus add the following function call:

    `setup_marker_at(<int marker> ,<time tref>);`

    With _marker_ being the integer you want to send and _tref_ set to the _expected_start_time_ of the stimulus that has been set up.
4.  Alternatively, you might want to send a marker as quickly as possible. Use the following function call for that:

    `send_marker(<int marker>);`

    This will set up a marker to be sent as quickly as possible. Because of internal logistics there is a short delay before the marker will be actually send. This delay is determined by the sum of `SCHEDULER_PRE_EMPT` and `SCHEDULER_PRE_EMPT_ERROR_TOLERANCE` settings. Using default settings the delay is around 7.5ms.

## Development mode
When you don't have a BeexyBox X available you can still test and integrate this module by setting `DEVELOP_MODE` to true.

`const bool DEVELOP_MODE = true;`

This makes the module work without a BeexyBox but simulates sending output.

## Logs
The module logs the status of failed and successfully transferred markers in a date-formatted file in a `markers-log` directory.

## Troubleshooting
Below are some common problems and their solutions. If these do not work please ask your technician for help. Make sure you run the experiment in such a way you can see the error output of Zep. This module outputs _WARNINGS_ and _ERRORS_ that might explain trouble.

### Module cannot find the device or connects to wrong device

#### Check the `DEVICE_SERIAL`
Sometimes the BeexyBox X device is not automagically found or opens the wrong device.
If this is the case you might need to define the device serial.
Do this by setting the `DEVICE_SERIAL` at the top of the `eeg_marker.zm` file.
If this variable is empty (`""`) it will results in an automatic lookup attempt.

The serial is printed on the bottom of the physical box of the device.
Alternatively, disconnecting all but one BeexyBox and run the [bxymonitor](https://www.beexy.nl/download/beexybox/).
Once connected this utility should print basic descriptors of the device which include the serial.

#### Check the device connections
[<img src="readme_images/BeexyBoxX.jpg" width="30%"></img>](readme_images/BeexyBoxX.jpg)

The BeexyBox X (`A`) requires three connections:
*   (`B`) The USB connection to the stimulus-presenting computer. If possible USB 3.x.
*   (`C`) The power-adapter connection. BeexyBox X does not use power-over-USB.
*   (`D`) The output connection. The 10-pin digital out needs to connect to the
first 10 pin of the parallel port. Here we use a ribbon cable and a 37-pin sub-d connector.

#### Check the connections using the bxymonitor application
Use [bxymonitor](https://www.beexy.nl/download/beexybox/) (utility for configuring, monitoring and testing BeexyBox devices) to see if you can actually connect to the BeexyBox (_e.g._ `bxymonitor`).


### Warnings when sending more than one marker simultaneously
    `!! WARNING - Marker 5's onset conflicts with a marker (4) that has already been scheduled !!`
Sending two markers simultaneously is not possible. A marker consists of a pulse-up and a pulse-down phase. The interval between up and down is the pulse length or duration. During this pulse we are sending a marker and another cannot start. The pulse _down_ needs to finish before a pulse _up_ can start. Hence there is a minimal pause between two marker onsets. By default this pause is the pulse length of the first marker plus some scheduling time. The module uses a scheduler that requires extra time for planning and transferring the marker data. This extends the actual required time for a marker.

For instance, if the marker' `pulse_length` is 20ms (default) and the `SCHEDULER_PRE_EMPT` setting is 5ms (default) the marker has a minimum of 25ms. Within this 25ms period no other markers can be set.

The solution is to redesign your experiment so sending two or more markers at nearly the same time does not happen.

### Overloading the scheduler
    `!! ERROR Overloading - Marker 9 failed to be pre-empted on time (1287.166ms too late) !!`
    `!! ERROR Overloading - Marker 1 failed to be scheduled to pre-empt on time (294.923ms too late) !!`

The scheduler fires slightly before the onset timing of an marker. When the scheduler fires (i.e. _expires_) it needs some CPU time to pre-emptively transfer the marker to the marker device. If the transfer does not occur on time the scheduler is considered _being overloaded_. This overload can result in a cascade of failed markers.

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
