const _basePathImage = 'asset/image';

enum ImageVariableData {
  dark(
    appLogo: '$_basePathImage/app_logo.png',
    peroduaLogo: '$_basePathImage/perodua_logo.png',
    accessoryDummy: '$_basePathImage/accessory_dummy.png',
  ),
  light(
    appLogo: '$_basePathImage/app_logo.png',
    peroduaLogo: '$_basePathImage/perodua_logo.png',
    accessoryDummy: '$_basePathImage/accessory_dummy.png',
  );

  final String appLogo;
  final String peroduaLogo;
  final String accessoryDummy;

  const ImageVariableData({
    required this.appLogo,
    required this.peroduaLogo,
    required this.accessoryDummy,
  });
}

const _basePathSvg = 'asset/svg';

enum SvgVariableData {
  dark(
    notificationIcon: '$_basePathSvg/notification_icon.svg',
    logoutIcon: '$_basePathSvg/logout_icon.svg',
    yardIn: '$_basePathSvg/receiving_icon.svg',
    defectFront: '$_basePathSvg/defect_front.svg',
    defectLeft: '$_basePathSvg/defect_left.svg',
    defectRight: '$_basePathSvg/defect_right.svg',
    defectBack: '$_basePathSvg/defect_back.svg',
    defectTop: '$_basePathSvg/defect_top.svg',
    deletePhoto: '$_basePathSvg/delete_photo.svg',
    report: '$_basePathSvg/report.svg',
    stagingIn: '$_basePathSvg/staging_in.svg',
    history: '$_basePathSvg/history.svg',
    updateVehicle: '$_basePathSvg/update_vehicle.svg',
    trackVehicle: '$_basePathSvg/track_vehicle.svg',
    changeLanguage: '$_basePathSvg/change_language.svg',
    steeringWheel: '$_basePathSvg/steering_wheel.svg',
    subItemArrow: '$_basePathSvg/sub_item_arrow.svg',
    arrivalAtOutlet: '$_basePathSvg/arrival_at_outlet.svg',
    vehicleCollection: '$_basePathSvg/vehicle_collection.svg',
    eWoStatusOpen: '$_basePathSvg/ewo_status_open.svg',
    eWoStatusPending: '$_basePathSvg/ewo_status_pending.svg',
    eWoStatusInProgress: '$_basePathSvg/ewo_status_progress.svg',
    eWoStatusCompleted: '$_basePathSvg/ewo_status_completed.svg',
    eWoStatusCancelled: '$_basePathSvg/ewo_status_cancelled.svg',
    warningSign: '$_basePathSvg/warning_sign.svg',
    verifiedTick: '$_basePathSvg/verified_tick.svg',
    doneArrivalOutlet: '$_basePathSvg/done_arrival_outlet.svg',
  ),
  light(
    notificationIcon: '$_basePathSvg/notification_icon.svg',
    logoutIcon: '$_basePathSvg/logout_icon.svg',
    yardIn: '$_basePathSvg/receiving_icon.svg',
    defectFront: '$_basePathSvg/defect_front.svg',
    defectLeft: '$_basePathSvg/defect_left.svg',
    defectRight: '$_basePathSvg/defect_right.svg',
    defectBack: '$_basePathSvg/defect_back.svg',
    defectTop: '$_basePathSvg/defect_top.svg',
    deletePhoto: '$_basePathSvg/delete_photo.svg',
    report: '$_basePathSvg/report.svg',
    stagingIn: '$_basePathSvg/staging_in.svg',
    history: '$_basePathSvg/history.svg',
    updateVehicle: '$_basePathSvg/update_vehicle.svg',
    trackVehicle: '$_basePathSvg/track_vehicle.svg',
    changeLanguage: '$_basePathSvg/change_language.svg',
    steeringWheel: '$_basePathSvg/steering_wheel.svg',
    subItemArrow: '$_basePathSvg/sub_item_arrow.svg',
    arrivalAtOutlet: '$_basePathSvg/arrival_at_outlet.svg',
    vehicleCollection: '$_basePathSvg/vehicle_collection.svg',
    eWoStatusOpen: '$_basePathSvg/ewo_status_open.svg',
    eWoStatusPending: '$_basePathSvg/ewo_status_pending.svg',
    eWoStatusInProgress: '$_basePathSvg/ewo_status_progress.svg',
    eWoStatusCompleted: '$_basePathSvg/ewo_status_completed.svg',
    eWoStatusCancelled: '$_basePathSvg/ewo_status_cancelled.svg',
    warningSign: '$_basePathSvg/warning_sign.svg',
    verifiedTick: '$_basePathSvg/verified_tick.svg',
    doneArrivalOutlet: '$_basePathSvg/done_arrival_outlet.svg',
  );

  final String notificationIcon;
  final String logoutIcon;
  final String yardIn;
  final String defectFront;
  final String defectLeft;
  final String defectRight;
  final String defectBack;
  final String defectTop;
  final String deletePhoto;
  final String report;
  final String stagingIn;
  final String history;
  final String updateVehicle;
  final String trackVehicle;
  final String changeLanguage;
  final String steeringWheel;
  final String subItemArrow;
  final String arrivalAtOutlet;
  final String vehicleCollection;
  final String eWoStatusOpen;
  final String eWoStatusPending;
  final String eWoStatusInProgress;
  final String eWoStatusCompleted;
  final String eWoStatusCancelled;
  final String warningSign;
  final String verifiedTick;
  final String doneArrivalOutlet;

  const SvgVariableData({
    required this.notificationIcon,
    required this.logoutIcon,
    required this.yardIn,
    required this.defectFront,
    required this.defectLeft,
    required this.defectRight,
    required this.defectBack,
    required this.defectTop,
    required this.deletePhoto,
    required this.report,
    required this.stagingIn,
    required this.history,
    required this.updateVehicle,
    required this.trackVehicle,
    required this.changeLanguage,
    required this.steeringWheel,
    required this.subItemArrow,
    required this.arrivalAtOutlet,
    required this.vehicleCollection,
    required this.eWoStatusOpen,
    required this.eWoStatusPending,
    required this.eWoStatusInProgress,
    required this.eWoStatusCancelled,
    required this.eWoStatusCompleted,
    required this.warningSign,
    required this.verifiedTick,
    required this.doneArrivalOutlet,
  });
}
