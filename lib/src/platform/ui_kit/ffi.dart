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

    vpLoadLutFile = lib.lookupFunction<VPLoadResourceStrFFI, VPLoadResourceStr>(
      'vpLoadFilterFile',
    );
    vpLoadVideoFile =
        lib.lookupFunction<VPLoadResourceStrFFI, VPLoadResourceStr>(
      'vpLoadVideoFile',
    );

    vpSetStateCallbacks =
        lib.lookupFunction<VPSetStateCallbacksFFI, VPSetStateCallbacks>(
      'vpSetStateCallback',
    );

    vpRemoveStateCallbacks =
        lib.lookupFunction<VPRemoveStateCallbacksFFI, VPRemoveStateCallbacks>(
      'vpRemoveStateCallback',
    );

    vpExportVideo = lib.lookupFunction<VPExportVideoFFI, VPExportVideo>(
      'vpExportVideo',
    );

    _initialized = true;
  }

  static late final VPTrigger vpPlay;
  static late final VPTrigger vpPause;

  static late final VPSeek vpSeek;
  static late final VPLoadResourceStr vpLoadLutFile;
  static late final VPLoadResourceStr vpLoadVideoFile;

  static late final VPSetStateCallbacks vpSetStateCallbacks;
  static late final VPRemoveStateCallbacks vpRemoveStateCallbacks;

  static late final VPExportVideo vpExportVideo;
}
