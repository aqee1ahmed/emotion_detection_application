import 'package:camera/camera.dart';
import 'package:emotion_detection_application/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraImage? _savedImage;
  CameraController? _cameraController;
  var output = "";

  @override
  void initState() {
    super.initState();
    loadModel();
    loadCamera();
  }

  loadCamera() async {
    _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    await _cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraController!.startImageStream((imageStream) {
          _savedImage = imageStream;
          runModel();
        });
      });
    });
  }

  runModel() async {
    if (_savedImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: _savedImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: _savedImage!.height,
        imageWidth: _savedImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      for (var element in recognitions!) {
        setState(() {
          output = element["label"];
        });
      }
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/detection_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Object Detection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width,
                child: _cameraController!.value.isInitialized
                    ? const Center(child: Text('No Image'))
                    : AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
              ),
            ),
            Text(
              output,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
