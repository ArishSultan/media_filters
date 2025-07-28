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

    vpLoadLutFilter = lib.lookupFunction<VPLoadLutFilterFFI, VPLoadLutFilter>(
      'vpLoadLutFilter',
    );

    vpRemoveLutFilter = lib.lookupFunction<VPTriggerFFI, VPTrigger>(
      'vpRemoveLutFilter',
    );

    vpLoadVideo = lib.lookupFunction<VPLoadVideoFFI, VPLoadVideo>(
      'vpLoadVideo',
    );

    vpSetStateCallbacks = lib.lookupFunction<VPSetCallbacksFFI, VPSetCallbacks>(
      'vpSetCallbacks',
    );

    vpRemoveStateCallbacks = lib.lookupFunction<VPTriggerFFI, VPTrigger>(
      'vpRemoveCallbacks',
    );

    vpSetTint = lib.lookupFunction<VPFilterFFI, VPFilter>('vpSetTint');
    vpSetExposure = lib.lookupFunction<VPFilterFFI, VPFilter>('vpSetExposure');
    vpSetContrast = lib.lookupFunction<VPFilterFFI, VPFilter>('vpSetContrast');
    vpSetSaturation = lib.lookupFunction<VPFilterFFI, VPFilter>(
      'vpSetSaturation',
    );
    vpSetTemperature = lib.lookupFunction<VPFilterFFI, VPFilter>(
      'vpSetTemperature',
    );

    // vpExportVideo = lib.lookupFunction<VPExportVideoFFI, VPExportVideo>(
    //   'vpExportVideo',
    // );

    _initialized = true;
  }

  static late final VPTrigger vpPlay;
  static late final VPTrigger vpPause;

  static late final VPSeek vpSeek;
  static late final VPLoadVideo vpLoadVideo;
  static late final VPTrigger vpRemoveLutFilter;
  static late final VPLoadLutFilter vpLoadLutFilter;

  static late final VPTrigger vpRemoveStateCallbacks;
  static late final VPSetCallbacks vpSetStateCallbacks;

  // static late final VPLoadResourceStr vpLoadLutFile;
  static late final VPFilter vpSetExposure;
  static late final VPFilter vpSetContrast;
  static late final VPFilter vpSetSaturation;
  static late final VPFilter vpSetTemperature;
  static late final VPFilter vpSetTint;
// static late final VPExportVideo vpExportVideo;
}
