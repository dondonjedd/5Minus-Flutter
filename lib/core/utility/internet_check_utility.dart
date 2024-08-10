import 'dart:async';

class InternetCheck {
  static InternetCheck? _instance;
  bool isDeviceConnected = false;
  Function? pingFunction;

  InternetCheck._internal() {
    _instance = this;
    Timer.periodic(const Duration(seconds: 6), (timer) {
      pingFunction?.call();
    });
  }
  subscribeInternetCheck({
    required Function()? onStatusOnline,
    required Function()? onStatusOffline,
    required String hostAddress,
    required String accessToken,
    required String sessionId,
    required bool checkConnectionDirectly,
    required Function(String type, String title, String message)? onError,
  }) {
    if (checkConnectionDirectly) {
      // BottomRepositoryData().ping(environment: environment, token: accessToken, sessionId: sessionId).then((res) {
      //   res.fold((failure) {
      //     isDeviceConnected = false;
      //     onStatusOffline?.call();
      //     onError?.call(failure.type, failure.title, failure.message);
      //   }, (success) {
      //     isDeviceConnected = true;
      //     onStatusOnline?.call();
      //   });
      // });
    }

    // pingFunction = () => BottomRepositoryData().ping(environment: environment, token: accessToken, sessionId: sessionId).then((res) {
    //       res.fold((failure) {
    //         isDeviceConnected = false;
    //         onStatusOffline?.call();
    //         onError?.call(failure.type, failure.title, failure.message);
    //       }, (success) {
    //         isDeviceConnected = true;
    //         onStatusOnline?.call();
    //       });
    //     });
  }

  triggerInternetCheck() {
    pingFunction?.call();
  }

  factory InternetCheck() => _instance ?? InternetCheck._internal();
}
