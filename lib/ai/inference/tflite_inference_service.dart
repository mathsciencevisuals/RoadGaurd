import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../detection/detected_object.dart';
import '../detection/detection_frame_result.dart';
import 'inference_result.dart';
import 'model_metadata.dart';

abstract class InterpreterFactory {
  Future<Interpreter> create(String assetPath);
}

class DefaultInterpreterFactory implements InterpreterFactory {
  const DefaultInterpreterFactory();

  @override
  Future<Interpreter> create(String assetPath) {
    return Interpreter.fromAsset(assetPath);
  }
}

abstract class AssetTextLoader {
  Future<String> load(String assetPath);
}

class RootBundleAssetTextLoader implements AssetTextLoader {
  const RootBundleAssetTextLoader();

  @override
  Future<String> load(String assetPath) {
    return rootBundle.loadString(assetPath);
  }
}

class TfliteInferenceService {
  TfliteInferenceService({
    InterpreterFactory interpreterFactory = const DefaultInterpreterFactory(),
    AssetTextLoader assetTextLoader = const RootBundleAssetTextLoader(),
  })  : _interpreterFactory = interpreterFactory,
        _assetTextLoader = assetTextLoader;

  static const String _modelAssetPath =
      'assets/models/roadguard_object_detection.tflite';
  static const String _labelsAssetPath = 'assets/models/labels.txt';
  static const String _defaultModelName = 'roadguard_object_detection';
  static const String _defaultModelVersion = 'unknown';

  final InterpreterFactory _interpreterFactory;
  final AssetTextLoader _assetTextLoader;

  Interpreter? _interpreter;
  ModelMetadata? _modelMetadata;
  bool _isInitialized = false;
  String? _initializationError;

  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;
  ModelMetadata? get modelMetadata => _modelMetadata;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      final Interpreter interpreter =
          await _interpreterFactory.create(_modelAssetPath);
      final List<String> labels = await _loadLabels();
      final List<int> inputShape = interpreter.getInputTensor(0).shape;

      _interpreter = interpreter;
      _modelMetadata = ModelMetadata(
        modelName: _defaultModelName,
        modelVersion: _defaultModelVersion,
        inputWidth: inputShape.length > 2 ? inputShape[2] : 0,
        inputHeight: inputShape.length > 1 ? inputShape[1] : 0,
        labels: labels,
      );
      _initializationError = null;
      _isInitialized = true;
    } on FlutterError catch (error) {
      _initializationError =
          'Model assets could not be loaded: ${error.message}';
      _isInitialized = false;
    } catch (error) {
      _initializationError = 'Unexpected inference initialization failure: $error';
      _isInitialized = false;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  Future<InferenceResult> runObjectDetection(
    InferenceImageInput imageInput, {
    required String frameId,
    required DateTime timestamp,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    if (!_isInitialized || _interpreter == null || _modelMetadata == null) {
      return InferenceResult(
        frameResult: DetectionFrameResult(
          frameId: frameId,
          timestamp: timestamp,
          detections: const <DetectedObject>[],
          processingTimeMs: 0,
          modelName: _defaultModelName,
          modelVersion: _defaultModelVersion,
        ),
        modelMetadata: _modelMetadata ??
            const ModelMetadata(
              modelName: _defaultModelName,
              modelVersion: _defaultModelVersion,
              inputWidth: 0,
              inputHeight: 0,
              labels: <String>[],
            ),
        errorMessage: _initializationError ??
            'Inference service is not initialized.',
      );
    }

    try {
      final Object preprocessedInput = _buildPlaceholderInputTensor(imageInput);
      final Map<int, Object> outputs = _buildPlaceholderOutputTensors();

      // TODO: Replace placeholder preprocessing with real image normalization,
      // resizing, color space conversion, and tensor layout conversion.
      _interpreter!.runForMultipleInputs(
        <Object>[preprocessedInput],
        outputs,
      );

      // TODO: Parse model-specific output tensors into DetectedObject values.
      final DetectionFrameResult frameResult = DetectionFrameResult(
        frameId: frameId,
        timestamp: timestamp,
        detections: const <DetectedObject>[],
        processingTimeMs: stopwatch.elapsedMilliseconds,
        modelName: _modelMetadata!.modelName,
        modelVersion: _modelMetadata!.modelVersion,
      );

      return InferenceResult(
        frameResult: frameResult,
        modelMetadata: _modelMetadata!,
      );
    } on ArgumentError catch (error) {
      return InferenceResult(
        frameResult: DetectionFrameResult(
          frameId: frameId,
          timestamp: timestamp,
          detections: const <DetectedObject>[],
          processingTimeMs: stopwatch.elapsedMilliseconds,
          modelName: _modelMetadata!.modelName,
          modelVersion: _modelMetadata!.modelVersion,
        ),
        modelMetadata: _modelMetadata!,
        errorMessage: 'Invalid inference input: $error',
      );
    } catch (error) {
      return InferenceResult(
        frameResult: DetectionFrameResult(
          frameId: frameId,
          timestamp: timestamp,
          detections: const <DetectedObject>[],
          processingTimeMs: stopwatch.elapsedMilliseconds,
          modelName: _modelMetadata!.modelName,
          modelVersion: _modelMetadata!.modelVersion,
        ),
        modelMetadata: _modelMetadata!,
        errorMessage: 'Unexpected inference failure: $error',
      );
    }
  }

  Future<List<String>> _loadLabels() async {
    final String labelsRaw = await _assetTextLoader.load(_labelsAssetPath);
    return labelsRaw
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  Object _buildPlaceholderInputTensor(InferenceImageInput imageInput) {
    final int inputHeight = _modelMetadata?.inputHeight ?? imageInput.height;
    final int inputWidth = _modelMetadata?.inputWidth ?? imageInput.width;

    return List<List<List<double>>>.generate(
      inputHeight,
      (_) => List<List<double>>.generate(
        inputWidth,
        (_) => List<double>.filled(3, 0),
        growable: false,
      ),
      growable: false,
    );
  }

  Map<int, Object> _buildPlaceholderOutputTensors() {
    return <int, Object>{
      0: List<List<List<double>>>.filled(
        1,
        List<List<double>>.filled(
          10,
          List<double>.filled(4, 0, growable: false),
          growable: false,
        ),
        growable: false,
      ),
      1: List<List<double>>.filled(
        1,
        List<double>.filled(10, 0, growable: false),
        growable: false,
      ),
      2: List<List<double>>.filled(
        1,
        List<double>.filled(10, 0, growable: false),
        growable: false,
      ),
      3: List<double>.filled(1, 0, growable: false),
    };
  }
}
