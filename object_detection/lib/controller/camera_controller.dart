import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> userCameras;
  late CameraImage cameraImage;

  bool isCameraInitialized = false;
  int cameraCount = 0;

  void updateCameraInitState({required bool cameraSts}) {
    isCameraInitialized = cameraSts;
    update();
  }

  Future<void> initCamera() async {
    if (await Permission.camera.request().isGranted) {
      userCameras = await availableCameras();
      cameraController = CameraController(userCameras[0], ResolutionPreset.max,
          imageFormatGroup: ImageFormatGroup.bgra8888);
      cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            detectObject(image);
          }
          update();
        });
      });
      updateCameraInitState(cameraSts: true);
    } else {
      print("Something went wrong.....");
    }

    update();
  }

  Future<void> detectObject(CameraImage cameraImage) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: cameraImage.planes.map((e) => e.bytes).toList(),
      asynch: true,
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      imageStd: 127.5,
      imageMean: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );
    print("Result $detector");
  }

  Future<void> initTFlow() async {
    try {
      await Tflite.loadModel(
          model: "assets/model.tflite",
          labels: "assets/labels.txt",
          isAsset: true,
          numThreads: 1,
          useGpuDelegate: false);
    } catch (e) {
      print("Failed to load model...");
    }
  }

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFlow();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }
}
