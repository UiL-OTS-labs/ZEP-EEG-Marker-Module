# ZEP-EEG-Marker-Module

This [Zep](https://www.beexy.nl/zep/wiki/doku.php) module provides a way
to send markers (i.e. triggers) from your Zep experiment to a parallel input port. One such input port is the USB receiver of the BioSemi EEG equipment. This allows you to send markers with Zep! Jeej.

The marker uses an external device which sends the actual markers. Markers (including their timings) are transferred to this device sometime before their required onset. The device can hold one marker at a time. Hence, if you setup markers in sequence the scheduler will plan to transfer them to the device milliseconds before their onset. This _pre-emptive_ loading scheme limits the frequency you can send markers at. This limit is ~40 Hz (25ms intervals).

## Requirements for this module
*   Zep version 1.14.4 or later
*   [BeexyBox type X](https://www.beexy.nl/responseboxes/)

## How to use this module
1.  Copy the file `eeg_markers.zm` from this repository to a location found by your experiment(_e.g._ your experiment's `/modules` directory).
1.  Within your experiment import the module by adding `import eeg_markers;` to
the top of your `.zp` file.
1.  Within your experiment script, after setting up the presentation of a
stimulus add the following function call:
    `setup_marker_at(<int marker> ,<time tref>);`
With _marker_ being the integer you want to send and _tref_ set to the _expected_start_time_ of the stimulus that has been setup.
1.  Alternatively if you want to send a marker directly you can use:
    `send_marker(<int marker>);`
This will setup a marker to be send as quickly as possible. The shortest time before the marker is sent is determined by the sum of `SCHEDULER_PRE_EMPT` and `SCHEDULER_PRE_EMPT_ERROR_TOLERANCE` settings. Using default settings this is 7.5ms.

# Troubleshooting
Below are some common problems and their solutions. If these do not work please ask your technician for help. Make sure you run the experiment in such a way you can see the error output of Zep. This module outputs _WARNINGS_ and _ERRORS_ that might explain trouble.

### Troubleshooting: Module cannot find the device

#### Check the `DEVICE_ADDRESS`
Sometimes the BeexyBox X device is not automagically found.
If this is the case you might need to define the device address manually.
Do this by setting the `DEVICE_ADDRESS` at the top of the `eeg_marker.zm` file.
This variable is empty (`""`) by default which results in an automatic lookup.

For Linux-based operating systems the address is generally one of:
*   _/dev/ttyACM0_
*   _/dev/ttyACM1_
*   ...

For Windows-based operating systems the address is generally one of:
*   _COM1_
*   _COM2_
*   ...

#### Check the device connections
[<img src="readme_images/BeexyBoxX.jpg" width="30%"></img>](readme_images/BeexyBoxX.jpg)

The BeexyBox X (`A`) requires three connections:
*   (`B`) The USB connection to the stimulus-presenting computer. If possible USB 3.x.
*   (`C`) The power-adapter connection. BeexyBox X does not use power-over-USB.
*   (`D`) The output connection. The 10-pin digital out needs to connect to the
first 10 pin of the parallel port. Here we use a ribbon cable and a 37-pin sub-d connector.

#### Check the connections using the bxymonitor application
Use [bxymonitor](https://www.beexy.nl/download/beexybox/) (utility for configuring, monitoring and testing BeexyBox devices) to see if you can actually connect to the BeexyBox (_e.g._ `bxymonitor /dev/ttyACM0`).


### Troubleshooting: Warnings when sending more than one marker simultaneously
    `!! WARNING - Marker 5's onset conflicts with a marker (4) that has already been scheduled !!`
Sending two markers simultaneously is not possible. A marker consists of a pulse-up and a pulse-down phase. The interval between up and down is the pulse length or duration. During this pulse we are sending a marker and another cannot start. The pulse _down_ needs to finish before a pulse _up_ can start. Hence there is a minimal pause between two marker onsets. By default this pause is the pulse length of the first marker plus some scheduling time. The module uses a scheduler that requires extra time for planning and transferring the marker data. This extends the actual required time for a marker.

For instance, if the marker' `pulse_length` is 20ms (default) and the `SCHEDULER_PRE_EMPT` setting is 5ms (default) the marker has a minimum of 25ms. Within this 25ms period no other markers can be set.

The solution is to redesign your experiment so sending two or more markers at nearly the same time does not happen.

### Troubleshooting: Overloading the scheduler
    `!! ERROR Overloading - Marker 9 failed to be pre-empted on time (1287.166ms too late) !!`
    `!! ERROR Overloading - Marker 1 failed to be scheduled to pre-empt on time (294.923ms too late) !!`

The scheduler fires slightly before the onset timing of an marker. When the scheduler fires (i.e. _expires_) it needs some CPU time to preemptively transfer the marker to the marker device. If the transfer does not occur on time the scheduler is considered _being overloaded_. This overload can result in a cascade of failed markers.

The solution is to lighten the load on the CPU during crucial and marked parts of your experiment. For instance, try to shuffle at the start of the experiment instead of at the start of a trial.

### Troubleshooting: The timing of the markers in the recording varies too much
Make sure you avoid using `send_marker()`. Use `send_marker()` if you want to insert a marker and care nothing for the accuracy of timing.

Try to use `setup_marker_at()` with the _expected_start_time_ of your stimulus object.
If using this function creates variation creates jitter something might be wrong with the way you setup the stimulus objects. Make sure you check for discrepancies between the _expected_start_time_ and the actual _start_time_ of you stimulus objects.

Note that the scheduler has some tolerance for scheduling-timing variance when sending the marker to the marker-sending device. The actual marker time is unaffected when the variance falls within this tolerance.

### Troubleshooting: EEG recordings with ActiView (Biosemi Software) suddenly pauses for no good reason
ActiView can be [configured](https://www.biosemi.com/faq/trigger_signals.htm) to start a pause or stop a pause on specific markers.
Check the .cfg you feed Actiview for the following:

     Example of .cfg text:
     PauseOff="254 //-1 is disabled, 0-255 is enabled"
     PauseOn="255 //-1 is disabled, 0-255 is enabled"
