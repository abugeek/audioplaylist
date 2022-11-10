import 'package:flutter/material.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

class VolumeSlider extends StatefulWidget {
  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double currentvol = 0.0;

  @override
  void initState() {
    PerfectVolumeControl.hideUI =
        true; //set if system UI is hided or not on volume up/down
    Future.delayed(Duration.zero, () async {
      currentvol = await PerfectVolumeControl.getVolume();
      setState(() {
        //refresh UI
      });
    });

    PerfectVolumeControl.stream.listen((volume) {
      setState(() {
        currentvol = volume;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 100),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            //Text("Current Volume: $currentvol"),
            const Divider(),
            Slider(
              value: currentvol,
              onChanged: (newvol) {
                currentvol = newvol;
                PerfectVolumeControl.setVolume(newvol); //set new volume
                setState(() {});
              },
              min: 0, //
              max: 1,
              divisions: 15,
            )
          ],
        ));
  }
}
