import 'dart:ffi';

import 'package:media_filters/src/platform/ui_kit/ffi_typedef.dart';

///
abstract final class DarwinFFI {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) {
      return;
    }

    final lib = DynamicLibrary.process();

    vpPlay = lib.lookupFunction<VPTriggerFFI, VPTrigger>('vpPlay');

    vpPause = lib.lookupFunction<VPTriggerFFI, VPTrigger>('vpPause');

    vpSeek = lib.lookupFunction<VPSeekFFI, VPSeek>('vpSeek');

    // vpLoadLutFile = lib.lookupFunction<VPLoadResourceStrFFI, VPLoadResourceStr>(
    //   'vpLoadFilterFile',
    // );

    vpLoadVideo = lib.lookupFunction<VPLoadVideoFFI, VPLoadVideo>(
      'vpLoadVideo',
    );

    vpSetStateCallbacks = lib.lookupFunction<VPSetCallbacksFFI, VPSetCallbacks>(
      'vpSetCallbacks',
    );

    vpRemoveStateCallbacks = lib.lookupFunction<VPTriggerFFI, VPTrigger>(
      'vpRemoveCallbacks',
    );

    // vpExportVideo = lib.lookupFunction<VPExportVideoFFI, VPExportVideo>(
    //   'vpExportVideo',
    // );

    _initialized = true;
  }

  static late final VPTrigger vpPlay;
  static late final VPTrigger vpPause;

  static late final VPSeek vpSeek;
  // static late final VPLoadResourceStr vpLoadLutFile;
  static late final VPLoadVideo vpLoadVideo;

  static late final VPTrigger vpRemoveStateCallbacks;
  static late final VPSetCallbacks vpSetStateCallbacks;

// static late final VPExportVideo vpExportVideo;
}
